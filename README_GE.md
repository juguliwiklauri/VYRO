# VYRO — საწყისი სამუშაო ვერსია

ეს პაკეტი ამატებს Android-ზე Firebase Email/Password რეგისტრაციასა და შესვლას,
მომხმარებლის პროფილის ჩანაწერს, მომხმარებლის სახელის უნიკალურობის შემოწმებას,
მომხმარებლების ძიებას და გასვლას.

## აუცილებელი Firebase ნაბიჯები
1. Firebase Console-ში პროექტში `vyro-404ba` ჩართე Authentication → Sign-in method → Email/Password.
2. შექმენი Firestore Database.
3. Firestore Rules-ში ჩასვი `firestore.rules`-ის შიგთავსი და გამოაქვეყნე.
4. Android აპის package name უნდა იყოს `com.vyro.app`. `google-services.json` უნდა იდოს `android/app/google-services.json`-ში.
5. Android Gradle პროექტში Google Services plugin უნდა იყოს ჩართული. FlutterFire/Gradle тохиргоог build გარემოში დასასრულებლად საჭიროა.

## Build
`flutter pub get`
`flutter build apk --release`

## ამ ეტაპის ფარგლები
ეს არის ფუნქციური პირველი ეტაპი (ანგარიშები/პროფილი/ძებნა), არა სრული გამოშვებისთვის მზად სოციალური ვიდეო პლატფორმა.
ვიდეოები, ჩატი, push შეტყობინებები, მოდერაცია და მონეტიზაცია ცალკე ეტაპებზე დაემატება და შემოწმდება.
