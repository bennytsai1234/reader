class BookType {
  static const int text = 0;
  static const int audio = 2;
  static const int image = 4;
  static const int file = 3;

  // --- 狀態位元 ---
  static const int local = 8;
  static const int notShelf = 16;
  static const int updateError = 32;

  static bool isAudio(int type) => (type & audio) != 0;
  static bool isImage(int type) => (type & image) != 0;
  static bool isLocal(int type) => (type & local) != 0;
  static bool isOnShelf(int type) => (type & notShelf) == 0;
}

