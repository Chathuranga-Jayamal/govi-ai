import base64
import json
from dataclasses import dataclass
from functools import lru_cache
from io import BytesIO
from pathlib import Path

import numpy as np
import timm
import torch
from PIL import Image
from pytorch_grad_cam import GradCAM
from pytorch_grad_cam.utils.image import show_cam_on_image
from pytorch_grad_cam.utils.model_targets import ClassifierOutputTarget

from app.core.config import get_settings


def _resolve_artifacts_dir() -> Path:
    # ARTIFACTS_DIR lets a deployment (e.g. a Docker build context scoped to
    # backend/, as on Fly.io) point at a copy of the artifacts placed inside
    # that context. When unset, this preserves the exact original local
    # behavior of resolving <repo root>/ai_model/artifacts.
    configured = get_settings().artifacts_dir
    if configured:
        return Path(configured)
    return Path(__file__).resolve().parents[3] / "ai_model" / "artifacts"


_ARTIFACTS_DIR = _resolve_artifacts_dir()
_METADATA_PATH = _ARTIFACTS_DIR / "model_metadata.json"
_CHECKPOINT_PATH = _ARTIFACTS_DIR / "govi_model.pt"

# The app's crop selector may send "chili" (single-l); the model's negative
# class bucket is keyed "chilli" (double-l) in crop_to_indices.
_CROP_ALIASES = {"chili": "chilli"}
_UNKNOWN_CROP_KEY = "unknown"

_LOW_CONFIDENCE_MESSAGE = "Unable to identify — please retake the photo in good light."
_NOT_A_LEAF_MESSAGE = "This doesn't look like a plant leaf — please retake the photo."


@dataclass
class PredictionResult:
    status: str
    crop: str | None
    disease: str | None
    confidence: float
    message: str | None
    heatmap_base64: str | None = None


class InvalidCropError(ValueError):
    pass


class InferenceService:
    def __init__(self) -> None:
        metadata = json.loads(_METADATA_PATH.read_text())
        self._labels: list[str] = metadata["labels"]
        self._crop_to_indices: dict[str, list[int]] = metadata["crop_to_indices"]
        self._confidence_threshold: float = metadata["confidence_threshold"]
        model_name: str = metadata["model_name"]
        _, _, height, width = metadata["input_shape"]

        # mean/std are read from the checkpoint itself (not hardcoded and not
        # from model_metadata.json) — govi_model.pt's state_dict is the plain
        # backbone with no normalization baked into the graph, so these
        # caller-applied values are the ones actually used at inference time.
        checkpoint = torch.load(
            _CHECKPOINT_PATH, map_location="cpu", weights_only=False
        )
        self._input_size = (height, width)
        self._mean = torch.tensor(checkpoint["mean"], dtype=torch.float32).view(3, 1, 1)
        self._std = torch.tensor(checkpoint["std"], dtype=torch.float32).view(3, 1, 1)

        self._model = timm.create_model(
            model_name, pretrained=False, num_classes=len(self._labels)
        )
        self._model.load_state_dict(checkpoint["state_dict"])
        self._model.eval()

        self._unknown_indices = self._crop_to_indices[_UNKNOWN_CROP_KEY]

    def normalize_crop(self, raw_crop: str) -> str:
        normalized = raw_crop.strip().lower()
        normalized = _CROP_ALIASES.get(normalized, normalized)
        if normalized == _UNKNOWN_CROP_KEY or normalized not in self._crop_to_indices:
            raise InvalidCropError(f"Unrecognized crop: {raw_crop!r}")
        return normalized

    def _preprocess(self, image_bytes: bytes) -> tuple[torch.Tensor, np.ndarray]:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        image = image.resize(self._input_size)
        # rgb_array is the 0-1 resized photo, kept alongside the normalized
        # tensor so Grad-CAM can overlay its heatmap on the same pixels the
        # model actually saw, without re-decoding or re-resizing the image.
        rgb_array = np.asarray(image, dtype=np.float32) / 255.0
        tensor = torch.from_numpy(rgb_array).permute(2, 0, 1)
        tensor = (tensor - self._mean) / self._std
        return tensor.unsqueeze(0), rgb_array

    def _generate_heatmap(
        self, tensor: torch.Tensor, rgb_array: np.ndarray, target_index: int
    ) -> str:
        # Built and torn down per call (not cached on the service) so its
        # forward/backward hooks never linger on the shared model singleton
        # between concurrent requests.
        with GradCAM(model=self._model, target_layers=[self._model.blocks[-1]]) as cam:
            grayscale_cam = cam(
                input_tensor=tensor, targets=[ClassifierOutputTarget(target_index)]
            )[0]

        overlay = show_cam_on_image(rgb_array, grayscale_cam, use_rgb=True)
        buffer = BytesIO()
        Image.fromarray(overlay).save(buffer, format="PNG")
        return base64.b64encode(buffer.getvalue()).decode("ascii")

    def predict(self, image_bytes: bytes, raw_crop: str) -> PredictionResult:
        crop = self.normalize_crop(raw_crop)
        # Union with the "unknown" indices so the not-a-leaf class stays
        # reachable as top-1 regardless of which crop is selected — otherwise
        # masking to only the selected crop's indices would make it
        # impossible to ever surface.
        allowed_indices = self._crop_to_indices[crop] + self._unknown_indices

        tensor, rgb_array = self._preprocess(image_bytes)
        with torch.no_grad():
            logits = self._model(tensor)[0]

        mask = torch.full_like(logits, float("-inf"))
        mask[allowed_indices] = 0.0
        probs = torch.softmax(logits + mask, dim=0)

        top_prob, top_index = torch.max(probs, dim=0)
        confidence = top_prob.item()
        label = self._labels[top_index.item()]
        predicted_crop, condition = label.split("___", 1)

        if predicted_crop == _UNKNOWN_CROP_KEY:
            return PredictionResult(
                status="not_a_leaf",
                crop=None,
                disease=None,
                confidence=confidence,
                message=_NOT_A_LEAF_MESSAGE,
            )

        if confidence < self._confidence_threshold:
            return PredictionResult(
                status="low_confidence",
                crop=None,
                disease=None,
                confidence=confidence,
                message=_LOW_CONFIDENCE_MESSAGE,
            )

        heatmap_base64 = self._generate_heatmap(tensor, rgb_array, top_index.item())

        return PredictionResult(
            status="ok",
            crop=predicted_crop,
            disease=condition,
            confidence=confidence,
            message=None,
            heatmap_base64=heatmap_base64,
        )


@lru_cache
def get_inference_service() -> InferenceService:
    return InferenceService()
