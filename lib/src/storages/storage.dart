abstract class Storage {
  Future<Map<String, dynamic>?> read();

  Future<void> write(Map<String, dynamic> data);

  Future<void> close();
}
