// Modèle User avec TypeORM et PostGIS
const { Entity, PrimaryGeneratedColumn, Column, Index, CreateDateColumn, UpdateDateColumn } = require('typeorm');
const { Point } = require('geojson');

@Entity('users')
@Index(['location'], { spatial: true }) // Index spatial PostGIS
@Index(['role'])
@Index(['phoneNumber'], { unique: true })
class User {
  @PrimaryGeneratedColumn()
  id;

  @Column({ type: 'varchar', length: 255 })
  name;

  @Column({ type: 'varchar', length: 20, unique: true })
  phoneNumber;

  @Column({ type: 'varchar', length: 20 })
  role; // 'client', 'driver', 'admin'

  @Column({ type: 'boolean', default: false })
  isVerified;

  @Column({
    type: 'geography',
    spatialFeatureType: 'Point',
    srid: 4326,
    nullable: true
  })
  location; // PostGIS geography type

  @CreateDateColumn()
  createdAt;

  @UpdateDateColumn()
  updatedAt;

  // Méthode pour mettre à jour la localisation
  async updateLocation(latitude, longitude) {
    this.location = {
      type: 'Point',
      coordinates: [longitude, latitude] // PostGIS utilise [lon, lat]
    };
    await this.save();
  }
}

module.exports = User;

