class FilipinoPronunciationService {
  // Filipino vowel pronunciation variations
  static const Map<String, List<String>> filipinoVowelVariations = {
    'a': ['a', 'ah', 'ey'],
    'e': ['e', 'eh', 'ay'],
    'i': ['i', 'ee', 'eye', 'e'],
    'o': ['o', 'oh', 'ow', 'u'],
    'u': ['u', 'oo', 'you', 'o'],
  };

  // Common Filipino consonant variations
  static const Map<String, List<String>> filipinoConsonantVariations = {
    'r': ['r', 'rr', 'd'],
    'ny': ['ny', 'ñ', 'ni', 'n'],
    'ng': ['ng', 'n', 'nang'],
    's': ['s', 'z'],
    'c': ['c', 'k', 's'],
    'f': ['f', 'p'],
    'v': ['v', 'b'],
    't': ['t', 'd'],
    'k': ['k', 'c', 'q'],
  };

  // Common Filipino word variations
  static const Map<String, List<String>> filipinoWordVariations = {
    // Level 1 words
    'a': ['a', 'ah'],
    'i': ['i', 'ee'],
    'o': ['o', 'oh'],
    'u': ['u', 'oo'],
    'e': ['e', 'eh'],

    // Level 2 words
    'at': ['at', 'aet', 'ad'],
    'it': ['it', 'id'],
    'on': ['on', 'un', 'an'],
    'up': ['up', 'ap', 'op'],
    'in': ['in', 'en'],
    'go': ['go', 'goh', 'gu'],
    'to': ['to', 'tu', 'too'],
    'do': ['do', 'du', 'doo'],
    'no': ['no', 'nu', 'noh'],
    'so': ['so', 'su', 'soh'],

    // Level 3 words
    'cat': ['cat', 'kat', 'car'],
    'dog': ['dog', 'dok', 'dug'],
    'sun': ['sun', 'son', 'san'],
    'run': ['run', 'ran', 'ron'],
    'big': ['big', 'bik', 'bik'],
    'red': ['red', 'rat', 'ret'],
    'blue': ['blue', 'bloo', 'blu'],
    'hot': ['hot', 'hat', 'ot'],
    'cold': ['cold', 'kold', 'kolt'],
    'new': ['new', 'nyu', 'neo'],
    'old': ['old', 'ol', 'ode'],
    'bad': ['bad', 'bat', 'bade'],
    'good': ['good', 'gud', 'gut'],
    'fun': ['fun', 'fan', 'pan'],
    'sad': ['sad', 'sade', 'sat'],

    // Level 4 words
    'tree': ['tree', 'tri', 'tiri'],
    'book': ['book', 'buk', 'bok'],
    'jump': ['jump', 'jamp', 'jom'],
    'talk': ['talk', 'tak', 'tok'],
    'frog': ['frog', 'prog', 'pog'],
    'duck': ['duck', 'dak', 'dok'],
    'bear': ['bear', 'ber', 'beyr'],
    'lion': ['lion', 'layon', 'lyon'],
    'tiger': ['tiger', 'tayger', 'tigre'],
    'horse': ['horse', 'hors', 'hors'],

    // Level 5 sentences (key words)
    'the': ['the', 'de', 'di'],
    'is': ['is', 'es', 'as'],
    'happy': ['happy', 'hapi', 'hapee'],
    'like': ['like', 'layk', 'lak'],
    'shines': ['shines', 'sayns', 'sinis'],
    'bright': ['bright', 'brayt', 'brait'],
    'we': ['we', 'wi', 'kami'],
    'can': ['can', 'kan', 'kayn'],
    'fast': ['fast', 'past', 'hast'],
    'barks': ['barks', 'bar', 'bark'],
    'loud': ['loud', 'lawd', 'laud'],
    'love': ['love', 'lab', 'lub'],
    'books': ['books', 'buks', 'boks'],
    'sings': ['sings', 'sing', 'sins'],
    'sweetly': ['sweetly', 'switli', 'switle'],
    'park': ['park', 'par', 'pork'],
    'swims': ['swims', 'swim', 'swenz'],
    'water': ['water', 'wader', 'tubig'],
    'eat': ['eat', 'it', 'et'],
    'my': ['my', 'may', 'aking'],
    'breakfast': ['breakfast', 'brekfas', 'almusal'],
    'grows': ['grows', 'gro', 'tubo'],
    'tall': ['tall', 'tal', 'tagas'],
    'school': ['school', 'skul', 'eskwela'],
    'flower': ['flower', 'flawer', 'bulaklak'],
    'smells': ['smells', 'smel', 'amoy'],
    'nice': ['nice', 'nays', 'maayos'],
    'picture': ['picture', 'pitcher', 'larawan'],
    'moon': ['moon', 'mun', 'buwan'],
    'song': ['song', 'sang', 'awit'],
    'car': ['car', 'kar', 'kotse'],
    'goes': ['goes', 'goz', 'pupunta'],
    'name': ['name', 'nem', 'pangalan'],
    'ball': ['ball', 'bol', 'bola'],
    'bounces': ['bounces', 'bawnses', 'tumatalbong'],
    'high': ['high', 'hay', 'taas'],
    'together': ['together', 'tugeder', 'sama'],
  };

  // Get pronunciation variations for a word
  static List<String> getPronunciationVariations(String word) {
    final normalizedWord = word.toLowerCase().trim();
    final variations = <String>[normalizedWord];

    // Check if word exists in our dictionary
    if (filipinoWordVariations.containsKey(normalizedWord)) {
      variations.addAll(filipinoWordVariations[normalizedWord]!);
    }

    // Generate variations based on vowel and consonant patterns
    final generatedVariations = _generateVariations(normalizedWord);
    variations.addAll(generatedVariations);

    // Remove duplicates and return
    return variations.toSet().toList();
  }

  // Generate variations based on Filipino pronunciation patterns
  static List<String> _generateVariations(String word) {
    final variations = <String>[];

    // Apply vowel variations
    for (final entry in filipinoVowelVariations.entries) {
      for (final variation in entry.value) {
        variations.add(word.replaceAll(entry.key, variation));
      }
    }

    // Apply consonant variations
    for (final entry in filipinoConsonantVariations.entries) {
      for (final variation in entry.value) {
        variations.add(word.replaceAll(entry.key, variation));
      }
    }

    return variations;
  }

  // Calculate similarity score between two words considering Filipino variations
  static double calculateFilipinoSimilarity(String target, String hypothesis) {
    final targetVariations = getPronunciationVariations(target);
    final normalizedHypothesis = hypothesis.toLowerCase().trim();

    double maxSimilarity = 0.0;

    for (final variation in targetVariations) {
      final similarity =
          _calculateLevenshteinSimilarity(variation, normalizedHypothesis);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
      }
    }

    return maxSimilarity;
  }

  // Calculate Levenshtein distance similarity
  static double _calculateLevenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty) return s2.isEmpty ? 1.0 : 0.0;
    if (s2.isEmpty) return 0.0;

    final maxLength = s1.length > s2.length ? s1.length : s2.length;
    final distance = _levenshteinDistance(s1, s2);

    return 1.0 - (distance / maxLength);
  }

  // Calculate Levenshtein distance
  static int _levenshteinDistance(String s1, String s2) {
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Check if pronunciation matches considering Filipino variations
  static bool matchesFilipinoPronunciation(String target, String hypothesis,
      {double threshold = 0.7}) {
    final similarity = calculateFilipinoSimilarity(target, hypothesis);
    return similarity >= threshold;
  }

  // Get phonetic breakdown for Filipino words
  static List<String> getPhoneticBreakdown(String word) {
    final normalizedWord = word.toLowerCase().trim();
    final phonemes = <String>[];

    // Simple phonetic breakdown for Filipino
    for (int i = 0; i < normalizedWord.length; i++) {
      final char = normalizedWord[i];

      // Handle consonant clusters
      if (i < normalizedWord.length - 1) {
        final cluster = normalizedWord.substring(i, i + 2);
        if (cluster == 'ng' ||
            cluster == 'ts' ||
            cluster == 'dy' ||
            cluster == 'ny') {
          phonemes.add(cluster);
          i++; // Skip next character
          continue;
        }
      }

      phonemes.add(char);
    }

    return phonemes;
  }
}
