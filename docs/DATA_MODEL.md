# Data Model

## General conventions
Use stable string IDs, ISO-8601 dates for generated activity timestamps, integer rupiah amounts, and explicit `is_demo: true` metadata at transaction boundaries. Fixture values are illustrative only.

## Entities
- Location: id, name, address_label, latitude/longitude-like schematic coordinates (not GPS), category, popularity.
- Driver: id, display_name, rating, completed_demo_trips, vehicle_id, avatar_asset, seed_order.
- Vehicle: id, category, label, capacity, base_fare, per_km_fare, estimated_minutes.
- Promo: id, code, title, discount_type, discount_value, minimum_fare, active.
- Restaurant: id, name, category, rating, eta_label, image_asset, featured.
- MenuItem: id, restaurant_id, name, description, price, image_asset, available.
- DeliveryOption: id, service_type, label, base_fee, per_km_fee, eta_label.
- Reward: id, title, points_cost, description, unlocked.
- DemoUser: id, display_name, avatar_asset, demo_wallet_balance, reward_points, favorite_location_ids.

## Referential integrity
Every driver.vehicle_id must exist in vehicles.json; every menu item restaurant_id must exist in restaurants.json; every favorite location ID must exist in locations.json. Fixture validation script should assert unique IDs and foreign keys.
