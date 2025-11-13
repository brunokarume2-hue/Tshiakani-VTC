// Entité PriceConfiguration pour stocker les tarifs configurables
const { EntitySchema } = require('typeorm');

const PriceConfiguration = new EntitySchema({
  name: 'PriceConfiguration',
  tableName: 'price_configurations',
  columns: {
    id: {
      type: 'int',
      primary: true,
      generated: true
    },
    // Tarifs de base
    basePrice: {
      type: 'decimal',
      precision: 10,
      scale: 2,
      default: 500.0,
      name: 'base_price',
      comment: 'Prix de base en CDF'
    },
    pricePerKm: {
      type: 'decimal',
      precision: 10,
      scale: 2,
      default: 200.0,
      name: 'price_per_km',
      comment: 'Prix par kilomètre en CDF'
    },
    // Multiplicateurs selon l'heure
    rushHourMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.5,
      name: 'rush_hour_multiplier',
      comment: 'Multiplicateur heures de pointe (7h-9h, 17h-19h)'
    },
    nightMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.3,
      name: 'night_multiplier',
      comment: 'Multiplicateur nuit (22h-6h)'
    },
    weekendMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.2,
      name: 'weekend_multiplier',
      comment: 'Multiplicateur week-end'
    },
    // Surge pricing
    surgeLowDemandMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 0.9,
      name: 'surge_low_demand_multiplier',
      comment: 'Multiplicateur demande faible (< 0.5 ratio)'
    },
    surgeNormalMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.0,
      name: 'surge_normal_multiplier',
      comment: 'Multiplicateur demande normale (0.5-1.0 ratio)'
    },
    surgeHighMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.2,
      name: 'surge_high_multiplier',
      comment: 'Multiplicateur demande élevée (1.0-1.5 ratio)'
    },
    surgeVeryHighMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.4,
      name: 'surge_very_high_multiplier',
      comment: 'Multiplicateur demande très élevée (1.5-2.0 ratio)'
    },
    surgeExtremeMultiplier: {
      type: 'decimal',
      precision: 5,
      scale: 2,
      default: 1.6,
      name: 'surge_extreme_multiplier',
      comment: 'Multiplicateur demande extrême (> 2.0 ratio)'
    },
    // Métadonnées
    isActive: {
      type: 'boolean',
      default: true,
      name: 'is_active',
      comment: 'Configuration active ou non'
    },
    description: {
      type: 'text',
      nullable: true,
      comment: 'Description de la configuration (ex: "Tarifs Kinshasa 2025")'
    },
    createdAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      name: 'created_at'
    },
    updatedAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      onUpdate: 'CURRENT_TIMESTAMP',
      name: 'updated_at'
    }
  },
  indices: [
    {
      name: 'idx_price_config_active',
      columns: ['isActive']
    }
  ]
});

module.exports = PriceConfiguration;

