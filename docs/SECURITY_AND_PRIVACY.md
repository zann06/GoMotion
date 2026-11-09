# Security and Privacy

## Data handling
The app uses fictional sample data and local in-memory state. Do not collect real names, addresses, phone numbers, payment credentials, or location. Address fields are demo labels selected from fixtures.

## Technical safeguards
- No network permission should be added unless a documented platform build requirement demands it; runtime networking remains prohibited.
- No secrets, API keys, analytics identifiers, or tokens.
- Validate fixture parsing and user-entered text lengths.
- Do not log user-entered text or wallet values unnecessarily.
- Keep reset explicit and explain that it clears local demo progress.
- Use platform secure storage only if a future approved requirement introduces genuinely sensitive local data; it is not needed for this simulator.

## Transparency
Label demo balance, simulated driver, fictional plate, estimated demo fare, and receipt. Never imply that a real ride, order, delivery, or payment has occurred.
