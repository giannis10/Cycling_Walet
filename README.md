# Cycling Races - Document Viewer

Μια Flutter εφαρμογή για Android/iOS που επιτρέπει την αποθήκευση και προβολή φωτογραφιών εγγράφων (UCI, ΕΟΠ, κάρτα υγείας) με zoom & pan λειτουργικότητα.

## Χαρακτηριστικά

- ✅ **Αυτόματη αποθήκευση**: Η τελευταία επιλεγμένη φωτογραφία αποθηκεύεται αυτόματα
- ✅ **Zoom & Pan**: Πλήρης λειτουργικότητα zoom και pan με το `photo_view` πακέτο
- ✅ **Επιλογή πηγής**: Επιλογή φωτογραφίας από gallery ή κάμερα
- ✅ **Indicator**: Εμφάνιση κατάστασης (αν υπάρχει αποθηκευμένο έγγραφο)
- ✅ **Modern UI**: Όμορφο και μοντέρνο interface
- ✅ **Offline**: Δεν απαιτείται internet connection

## Εγκατάσταση

1. Βεβαιωθείτε ότι έχετε εγκαταστήσει το Flutter SDK
2. Κλωνοποιήστε το repository
3. Εκτελέστε:
   ```bash
   flutter pub get
   ```

## Εκτέλεση

### Android
```bash
flutter run
```

### iOS
```bash
flutter run
```

## Χρήση

1. **Πρώτη χρήση**: Πατήστε το κουμπί "Αλλαγή" για να προσθέσετε φωτογραφία
2. **Επιλογή πηγής**: Επιλέξτε μεταξύ κάμερας ή gallery
3. **Προβολή**: Η φωτογραφία εμφανίζεται σε fullscreen με zoom & pan
4. **Αποθήκευση**: Η φωτογραφία αποθηκεύεται αυτόματα και θα φορτώνει την επόμενη φορά

## Δομή Project

```
lib/
  └── main.dart          # Κύριο αρχείο εφαρμογής
android/
  └── app/src/main/
      └── AndroidManifest.xml  # Android permissions
ios/
  └── Runner/
      └── Info.plist     # iOS permissions
pubspec.yaml             # Dependencies
```

## Dependencies

- `shared_preferences`: Για αποθήκευση της διαδρομής της φωτογραφίας
- `image_picker`: Για επιλογή φωτογραφίας από gallery/camera
- `photo_view`: Για zoom & pan λειτουργικότητα

## Permissions

### Android
- `CAMERA`: Για λήψη φωτογραφίας
- `READ_EXTERNAL_STORAGE`: Για πρόσβαση στη gallery
- `WRITE_EXTERNAL_STORAGE`: Για αποθήκευση φωτογραφιών

### iOS
- `NSCameraUsageDescription`: Για πρόσβαση στην κάμερα
- `NSPhotoLibraryUsageDescription`: Για πρόσβαση στη φωτογραφική βιβλιοθήκη
- `NSPhotoLibraryAddUsageDescription`: Για αποθήκευση φωτογραφιών

## Σημειώσεις

- Η εφαρμογή αποθηκεύει μόνο τη διαδρομή της φωτογραφίας, όχι την ίδια την εικόνα
- Η φωτογραφία πρέπει να παραμείνει στη συσκευή για να είναι διαθέσιμη
- Υποστηρίζει όλες τις κατευθύνσεις οθόνης
- Εξαιρετική για την προβολή εγγράφων όπως UCI, ΕΟΠ, κάρτες υγείας 