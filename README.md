# Cycling Wallet

Μια Flutter εφαρμογή για γρήγορη αποθήκευση και προβολή αγωνιστικών εγγράφων
ποδηλασίας (UCI, ΕΟΠ, κάρτα υγείας) με ασφαλή, offline πρόσβαση.

## Για ποιον είναι

- Αθλητές/συνοδοί που χρειάζονται άμεση επίδειξη εγγράφων σε αγώνα
- Χρήστες που θέλουν όλα τα έγγραφα οργανωμένα στο κινητό χωρίς cloud

## Χαρακτηριστικά

- Κάρτες εγγράφων με 1–2 φωτογραφίες ανά έγγραφο
- Fullscreen προβολή με zoom & pan
- Επιλογή από κάμερα ή συλλογή
- Αυτόματη αποθήκευση και offline λειτουργία
- Προσωρινή ενίσχυση φωτεινότητας κατά την προβολή

## Αποθήκευση & ιδιωτικότητα

- Οι φωτογραφίες αντιγράφονται σε ιδιωτικό χώρο της εφαρμογής
  (Application Documents / `app_flutter`) και δεν εξαρτώνται από το album.
- Αν διαγραφεί μια φωτογραφία από τη συλλογή, η εφαρμογή κρατά το δικό της αντίγραφο.
- Δεν γίνεται αποστολή δεδομένων σε server ή cloud.

## Τεχνικές λεπτομέρειες

- Flutter (Android/iOS)
- Τοπικό metadata σε `shared_preferences`
- Αρχεία εικόνας σε app-specific directory μέσω `path_provider`
- Προβολή εικόνας με `photo_view`, επιλογή με `image_picker`

## Δομή project

```
lib/
  main.dart
  models/document.dart
  screens/home_screen.dart
  services/storage_service.dart
  widgets/document_card.dart
```

## Εγκατάσταση

1. Εγκατάσταση Flutter SDK
2. `flutter pub get`

## Έτοιμα builds

Για εγκατάσταση σε Android ή iPhone, υπάρχουν έτοιμες εκδόσεις στα GitHub Releases.

## Εκτέλεση

- `flutter run`

## Permissions

### Android
- `CAMERA`
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE` (ανάλογα με έκδοση Android)

### iOS
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

## Σημειώσεις

- Τα δεδομένα αποθηκεύονται τοπικά και διαγράφονται με απεγκατάσταση.
- Αν αλλάξει φωτογραφία, αντικαθίσταται το αντίγραφο στο app directory.