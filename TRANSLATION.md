# Translation

Anytime uses the [intl](https://pub.dev/packages/intl)
and [intl_translation](https://pub.dev/packages/intl_translation)
packages for handling string translations, and a custom `LocalizationsDelegate` to allow Anytime to
use custom
language resources when required.

All the language resources can be found under the `lib/l10n` directory.

### Translation Process

The translation process requires a few steps: create the language reference in code, generate the
ARB
file(s), translate the new strings into the desired locales then generate the language bindings.

#### New locales

If you are translating Anytime into a new language, add the locale to the `supportedLocales` as part
of
the `MaterialApp` construction within the main `AnytimePodcastApp` class.

Add the language code to the `isSupported` methods in `L.dart`.

#### Define messages

Check the `L.dart` file to see if it already contains the string you are looking for.

If not, create the new message in `L.dart`. Use an existing message as a template ensuring the
message name makes it
clear what/where the message is used.

#### Generate ARB files

Open a terminal or command line window and, from the project case, run the following command:

`dart run intl_translation:extract_to_arb --output-dir=lib/l10n lib/l10n/L.dart`

This will add the new messages to the master `intl_messages.arb` file.

#### Translate ARB files.

Copy the new entries in the `intl_messages.arb` file to the `intl_en.arb` file and the locale file
you are translating
to. Translate the new messages in the locale ARB file.

Once translation is complete, run the following command to generate the language bindings:

`dart run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/l10n/L.dart lib/l10n/intl_*.arb`