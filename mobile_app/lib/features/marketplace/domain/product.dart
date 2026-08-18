import 'package:flutter/material.dart';

enum ProductCategory {
  fertilizer,
  pesticide,
  tools;

  String get label {
    switch (this) {
      case ProductCategory.fertilizer:
        return 'Fertilizer';
      case ProductCategory.pesticide:
        return 'Pesticide';
      case ProductCategory.tools:
        return 'Tools';
    }
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageIcon,
    required this.rating,
    required this.isBestSeller,
    required this.shortDescription,
    required this.usageInstructions,
    this.warningText,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final double price;
  final IconData imageIcon;
  final double rating;
  final bool isBestSeller;
  final String shortDescription;
  final List<String> usageInstructions;
  final String? warningText;

  String get priceLabel => 'Rs. ${price.toStringAsFixed(0)}';
}

const List<Product> mockProducts = [
  Product(
    id: 'fert-01',
    name: 'Lanka NPK 15:15:15 Fertilizer',
    category: ProductCategory.fertilizer,
    price: 2450,
    imageIcon: Icons.grass,
    rating: 4.5,
    isBestSeller: true,
    shortDescription:
        'Balanced NPK blend for paddy and vegetable crops, supporting '
        'strong root development and higher yields through the growing '
        'season.',
    usageInstructions: [
      'Apply 50kg per acre at the start of the growing season.',
      'Broadcast evenly across the field and water in lightly.',
      'Repeat a top-up application 6 weeks after planting.',
    ],
    warningText:
        'Do not exceed recommended dosage — over-application can burn '
        'young roots. Keep away from children and store in a dry place.',
  ),
  Product(
    id: 'fert-02',
    name: 'Ceylon Urea Prill 46%',
    category: ProductCategory.fertilizer,
    price: 1890,
    imageIcon: Icons.eco,
    rating: 4.2,
    isBestSeller: false,
    shortDescription:
        'High-nitrogen prilled urea for rapid vegetative growth in rice, '
        'tea, and vegetable crops.',
    usageInstructions: [
      'Apply 25kg per acre split across two applications.',
      'Apply after rainfall or irrigation for best absorption.',
      'Avoid direct contact with plant leaves and stems.',
    ],
    warningText:
        'Highly concentrated nitrogen source — over-use can scorch '
        'foliage and pollute nearby water sources. Wear gloves when '
        'handling.',
  ),
  Product(
    id: 'fert-03',
    name: 'Tea Master Foliar Spray',
    category: ProductCategory.fertilizer,
    price: 950,
    imageIcon: Icons.spa,
    rating: 4.6,
    isBestSeller: true,
    shortDescription:
        'Fast-acting foliar nutrient spray formulated for tea estates, '
        'improving leaf colour and flush quality.',
    usageInstructions: [
      'Dilute 20ml per litre of water.',
      'Spray evenly over foliage in the early morning or evening.',
      'Repeat every 2 weeks during the growing flush.',
    ],
    warningText:
        'Avoid spraying in direct midday sun. Do not harvest leaves '
        'within 3 days of application.',
  ),
  Product(
    id: 'pest-01',
    name: 'Ceylon Agro Fungicide',
    category: ProductCategory.pesticide,
    price: 1180,
    imageIcon: Icons.bug_report,
    rating: 4.3,
    isBestSeller: true,
    shortDescription:
        'Broad-spectrum fungicide effective against blast, blight, and '
        'other common fungal diseases in rice and vegetable crops.',
    usageInstructions: [
      'Mix 2ml per litre of water.',
      'Spray affected plants thoroughly, covering both leaf surfaces.',
      'Repeat every 7–10 days until symptoms clear.',
    ],
    warningText:
        'Toxic if inhaled or swallowed. Wear a mask and gloves during '
        'application and observe a 7-day pre-harvest interval.',
  ),
  Product(
    id: 'pest-02',
    name: 'Nawaloka Rice Guard',
    category: ProductCategory.pesticide,
    price: 1320,
    imageIcon: Icons.shield_outlined,
    rating: 4.1,
    isBestSeller: false,
    shortDescription:
        'Insecticide targeted at stem borers and leaf folders in paddy '
        'fields, protecting yield during the vegetative stage.',
    usageInstructions: [
      'Mix 1.5ml per litre of water.',
      'Apply during early morning or late evening for best effect.',
      'Avoid application during flowering to protect pollinators.',
    ],
    warningText:
        'Harmful to bees — do not spray during flowering. Keep livestock '
        'out of treated fields for 24 hours.',
  ),
  Product(
    id: 'pest-03',
    name: 'AgroLanka Systemic Insecticide',
    category: ProductCategory.pesticide,
    price: 1450,
    imageIcon: Icons.pest_control,
    rating: 4.0,
    isBestSeller: false,
    shortDescription:
        'Systemic insecticide absorbed by the plant for long-lasting '
        'protection against sap-sucking pests in vegetables and tea.',
    usageInstructions: [
      'Mix 1ml per litre of water.',
      'Apply as a foliar spray or soil drench at the base of the plant.',
      'Do not apply more than 3 times per growing season.',
    ],
    warningText:
        'Highly toxic to aquatic life — do not apply near ponds or '
        'waterways. Store locked away from children.',
  ),
  Product(
    id: 'tool-01',
    name: 'Hunter Knapsack Sprayer 16L',
    category: ProductCategory.tools,
    price: 4500,
    imageIcon: Icons.water_drop_outlined,
    rating: 4.7,
    isBestSeller: true,
    shortDescription:
        'Durable 16-litre manual knapsack sprayer with adjustable nozzle, '
        'built for daily use on fertilizer and pesticide applications.',
    usageInstructions: [
      'Fill the tank to the marked level and secure the lid.',
      'Pump the handle to build pressure before spraying.',
      'Rinse thoroughly with clean water after each use.',
    ],
    warningText: null,
  ),
  Product(
    id: 'tool-02',
    name: 'CeylonSteel Pruning Shears',
    category: ProductCategory.tools,
    price: 1250,
    imageIcon: Icons.content_cut,
    rating: 4.4,
    isBestSeller: false,
    shortDescription:
        'Sharp, rust-resistant pruning shears for tea plucking and '
        'general crop maintenance, with a comfortable non-slip grip.',
    usageInstructions: [
      'Clean and dry the blades before first use.',
      'Oil the pivot joint regularly to keep the action smooth.',
      'Sharpen blades periodically for a clean cut.',
    ],
    warningText: null,
  ),
  Product(
    id: 'tool-03',
    name: 'Lanka Hand Weeder',
    category: ProductCategory.tools,
    price: 650,
    imageIcon: Icons.build,
    rating: 4.2,
    isBestSeller: false,
    shortDescription:
        'Lightweight hand weeder for precise removal of weeds between '
        'rows without disturbing crop roots.',
    usageInstructions: [
      'Grip the handle firmly and work the blade just below the soil '
          'surface.',
      'Pull weeds out fully, including the root, to prevent regrowth.',
      'Wash and dry after use to prevent rusting.',
    ],
    warningText: null,
  ),
];
