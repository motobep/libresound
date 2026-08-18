// ignore_for_file: annotate_overrides

abstract class Lang {
  abstract String type_;
  abstract String code_;

  abstract String Settings;
  abstract String Appearance;
  abstract String Sync;
  abstract String Plugins;
  abstract String Files;
  abstract String Selected_folder;
  abstract String Search;

  abstract String Unknown_Title;
  abstract String Unknown_Artist;
  abstract String Unknown_Album;
  abstract String Unknown_Year;
  abstract String Unknown_Track;
  abstract String Unknown_Genre;

  // Dialogs
  abstract String Add_to_queue;
  abstract String Play_next;
  abstract String Clear_queue;
  abstract String To_artist;
  abstract String Like;
  abstract String Dislike;
  abstract String Add_to_playlist;
  abstract String Delete;
  abstract String Delete_playlist;
  abstract String Remove_from_playlist;
  abstract String Modify_playlist;
  abstract String New_playlist;
  abstract String Download;
  abstract String Downloading;
  abstract String Music_folder_not_specified;
  abstract String The_file_already_exists;
  abstract String Overwrite_it;
  abstract String Create_a_new_file_named;

  abstract String Delete_this_song;
  abstract String Delete_these_songs;
  abstract String Delete__q;

  abstract String Name;
  abstract String Actions;
  abstract String Queue_is_empty;
  abstract String Queue;
  abstract String Lyrics;

  // Notifications
  abstract String saved_from_cache;
  abstract String already_loading;
  abstract String Failed_to_load;
  abstract String The_item_has_already_been_removed;
  abstract String No_data;
  abstract String downloaded;
  abstract String Error_occurred;
  abstract String Failed_to_load_folder;

  // Guards
  abstract String Select_the_music_folder;
  abstract String Grant_audio_permission;
  abstract String Grant_access_to_storage;
  abstract String Grant;
  abstract String Reload;
  abstract String Use_default_music_folder;
  abstract String Or;

  // Buttons
  abstract String Ok;
  abstract String Submit;
  abstract String Save;
  abstract String Save_palette;
  abstract String Cancel;
  abstract String Reset;
  abstract String Choose;
  abstract String Yes;
  abstract String No;

  // Settings
  abstract String Folder_with_music;
  abstract String Cache;
  abstract String Language;
  abstract String Key_bindings;
  abstract String Volume;
  abstract String Equalizer;
  abstract String Licenses;
  abstract String For_developers;
  abstract String Clear;
  abstract String Cache_cleared;
  abstract String phrase__cache_errored;

  abstract String Quick_pick;
  abstract String Music_folder;
  abstract String Downloads_folder;
  abstract String tracks__genetive;
  abstract String phrase__no_music_in_folder;

  abstract String Enabled;

  // Key bindings
  abstract String Action;
  abstract String Keys;
  abstract String Press_keys;
  abstract String Conflicts_have_occurred;
  abstract String will_be_reset_when_you_press_save;

  abstract String kb__toggle_playback;
  abstract String kb__play_prev;
  abstract String kb__play_next;
  abstract String kb__shuffle;
  abstract String kb__toggle_repeat;
  abstract String kb__show_current_item_dialog;
  abstract String kb__choose;
  abstract String kb__focus_up;
  abstract String kb__focus_down;
  abstract String kb__to_bottom;
  abstract String kb__to_top;
  abstract String kb__focus_left_pane;
  abstract String kb__focus_right_pane;
  abstract String kb__to_prev_tab;
  abstract String kb__to_next_tab;
  abstract String kb__back;
  abstract String kb__show_item_dialog;
  abstract String kb__focus_search;
  abstract String kb__unfocus;
  abstract String kb__prev_suggestion;
  abstract String kb__next_suggestion;

  // Appearance
  abstract String Color_Palettes;
  abstract String Colors;

  abstract String Text;
  abstract String Background;
  abstract String Subtitle;
  abstract String Primary;
  abstract String Accent;

  abstract String Dynamic_theme;
  abstract String Off;
  abstract String Only_on_the_playback_page;
  abstract String Everywhere;

  abstract String Custom_Font;
  abstract String Supported_formats;
  abstract String Font;
  abstract String Thumbnail_corners;
  abstract String Cover_corners;
  abstract String Pick_color;

  // Sync
  abstract String Deactivate;
  abstract String Activate;

  abstract String Connecting;
  abstract String Accept;
  abstract String Pair;
  abstract String Unpair;
  abstract String Retry;
  abstract String Preparation;

  abstract String Synchronize;
  abstract String Download_files_from_partners_device;
  abstract String Clean;
  abstract String Delete_extra_files_on_this_device;

  abstract String Error;
  abstract String Errors;

  abstract String No_network_connection;
  abstract String IP_address_not_found;
  abstract String Network_unreachable;
  abstract String Connect_to_the_network_and_press_Retry;
  abstract String phrase__bad_activation;
  abstract String Unknown_error;

  abstract String Mine;
  abstract String Partner;
  abstract String Partners;
  abstract String Leave_as_is;
  abstract String phrase__Playlist_conflict;
  abstract String Error_from_partner;

  abstract String Unable_to_access_path;
  abstract String Path_not_found;
  abstract String File_system_error;
  abstract String Unable_to_read_directory;
  abstract String Undefind_error;

  abstract String Sending_files;
  abstract String Downloading_files;
  abstract String Cleaning_files;

  abstract String About_modes;
  abstract String File_sharing_with_a_partner;
  abstract String Downloading_file_from_partner;
  abstract String Removing_extra_files_that_the_partner_does_not_have;
  abstract String Remove_extra_files_that_the_partner_does_not_have__q;
  abstract String See;

  abstract String phrase__mine;
  abstract String phrase__partner;
  abstract String phrase__as_is;

  abstract String phrase__no_active_devices_to_pair_with;

  // Plugins
  abstract String Download_plugins;
  abstract String Network_error;

  abstract String Install_from_zip_file;
  abstract String Install_from_the_server;
  abstract String Error_occurred_while_extracting_zip_archive;
  abstract String Error_occurred_while_downloading_plugin;
  abstract String Error_occurred_while_deleting_plugin;
  abstract String phrase__Plugin_successfully_installed;
  abstract String Failed_downloading_plugin;
  abstract String Plugin_not_found;
  abstract String The_plugin_has_been_reloaded;

  abstract String My_plugins;
  abstract String Home;
  abstract String plugins__genetive;
  abstract String Add_url;
  abstract String Url;

  abstract String Title;
  abstract String Long_title;
  abstract String Description;
  abstract String Version;
  abstract String Minimum_app_version;
  abstract String Permissions;
  abstract String Homepage;
  abstract String Repository;
  abstract String Author;
  abstract String Published_at;
  abstract String Unpacked_size;
  abstract String Deleted_User;

  abstract String Approved_by;

  abstract String phrase__plugin_welcome;
  abstract String Warning;
  abstract String phrase__disclaimer;
  // abstract String Ive_read_and_understood;
  abstract String Plugin_settings;
  abstract String
      Automatically_load_the_home_page_when_entering_the_plugins_page;
  abstract String Automatic_check_for_plugin_updates;
  abstract String This_message_will_not_appear_again;
  abstract String Continue;

  // FsSource
  abstract String Tracks;
  abstract String Playlists;
  abstract String Artists;
  abstract String Albums;

  abstract String songs;

  abstract String Favourites;

  abstract String phrase__only_allowed;

  abstract String Autoplay;
}

class EnLang implements Lang {
  String type_ = 'english';
  String code_ = 'en';
  // Sidebar
  String Settings = 'Settings';
  String Appearance = 'Appearance';
  String Sync = 'Sync';
  String Plugins = 'Plugins';
  String Files = 'Filesystem';
  String Selected_folder = 'Selected folder';
  String Search = 'Search';

  // Music item
  String Unknown_Title = 'Unknown Title';
  String Unknown_Artist = 'Unknown artist';
  String Unknown_Album = 'Unknown Album';
  String Unknown_Year = 'Unknown Year';
  String Unknown_Track = 'Unknown Track';
  String Unknown_Genre = 'Unknown Genre';

  // Dialogs
  String Add_to_queue = 'Add to queue';
  String Play_next = 'Play next';
  String Clear_queue = 'Clear queue';
  String To_artist = 'To artist';
  String Like = 'Like';
  String Dislike = 'Dislike';
  String Add_to_playlist = 'Add to playlist';
  String Delete = 'Delete';
  String Delete_playlist = 'Delete playlist';
  String Remove_from_playlist = 'Remove from playlist';
  String Modify_playlist = 'Modify playlist';
  String New_playlist = 'New playlist';
  String Download = 'Download';
  String Downloading = 'Downloading';
  String Music_folder_not_specified = 'Music folder not specified';
  String The_file_already_exists = 'The file {} already exists';
  String Overwrite_it = 'Overwrite it';
  String Create_a_new_file_named = 'Create a new file named';

  String Delete__q = 'Delete?';
  String Delete_this_song = 'Delete this song?';
  String Delete_these_songs = 'Delete these songs?';

  String Name = 'Name';
  String Actions = 'Actions';
  String Queue_is_empty = 'Queue is empty';
  String Queue = 'Queue';
  String Lyrics = 'Lyrics';

  // Notifications
  String saved_from_cache = 'saved from cache';
  String already_loading = 'already loading';
  String Failed_to_load = 'Failed to load';
  String The_item_has_already_been_removed =
      'The item has already been removed';
  String No_data = 'No data';
  String downloaded = 'downloaded';
  String Error_occurred = 'An error occurred';
  String Failed_to_load_folder = 'Failed to load folder';

  // Guards
  String Select_the_music_folder = 'Select the music folder';
  String Grant_audio_permission = 'Grant audio permission';
  String Grant_access_to_storage = 'Grant access to storage';
  String Grant = 'Grant';
  String Reload = 'Reload';
  String Use_default_music_folder = 'Use default music folder';
  String Or = 'Or';

  // Buttons
  String Ok = 'Ok';
  String Submit = 'Submit';
  String Save = 'Save';
  String Save_palette = 'Save palette';
  String Cancel = 'Cancel';
  String Reset = 'Reset';
  String Choose = 'Choose';
  String Yes = 'Yes';
  String No = 'No';

  // Settings
  String Folder_with_music = 'Folder with music';
  String Cache = 'Cache';
  String Language = 'Language';
  String Key_bindings = 'Key bindings';
  String Volume = 'Volume';
  String Equalizer = 'Equalizer';
  String Licenses = 'Licenses';
  String For_developers = 'For developers';
  String Clear = 'Clear';
  String Cache_cleared = 'Cache cleared';
  String phrase__cache_errored =
      'Something went wrong while clearing the cache';

  String Quick_pick = 'Quick pick';
  String Music_folder = 'Music folder';
  String Downloads_folder = 'Downloads folder';
  String tracks__genetive = 'tracks';
  String phrase__no_music_in_folder =
      '''There are no music files in the "{}" folder.
Please add music to this folder or select a different folder in the Settings.''';

  String Enabled = 'Enabled';

  // Key bindings
  String Action = 'Action';
  String Keys = 'Keys';
  String Press_keys = 'Press the keys';
  String Conflicts_have_occurred = 'Conflicts have occurred';
  String will_be_reset_when_you_press_save =
      'will be reset when you press "Save"';

  String kb__toggle_playback = 'Play/pause';
  String kb__play_prev = 'Play prev';
  String kb__play_next = 'Play next';
  String kb__shuffle = 'Shuffle';
  String kb__toggle_repeat = 'Toggle repeat';
  String kb__show_current_item_dialog = 'Show current element dialog';
  String kb__choose = 'Choose element';
  String kb__focus_up = 'Focus up';
  String kb__focus_down = 'Focus down';
  String kb__to_bottom = 'To the bottom';
  String kb__to_top = 'To the top';
  String kb__focus_left_pane = 'Focus left pane';
  String kb__focus_right_pane = 'Focus right pane';
  String kb__to_prev_tab = 'To the previous tab';
  String kb__to_next_tab = 'To the next tab';
  String kb__back = 'Back';
  String kb__show_item_dialog = 'Show current dialog';
  String kb__focus_search = 'Focus search field';
  String kb__unfocus = 'Unfocus';
  String kb__prev_suggestion = 'Previous search suggestion';
  String kb__next_suggestion = 'Next search suggestion';

  // Appearance
  String Color_Palettes = 'Color Palettes';
  String Colors = 'Colors';

  String Text = 'Text';
  String Background = 'Background';
  String Subtitle = 'Subtitle';
  String Primary = 'Primary';
  String Accent = 'Accent';

  String Dynamic_theme = 'Dynamic theme';
  String Off = 'Off';
  String Only_on_the_playback_page = 'Only on the playback page';
  String Everywhere = 'Everywhere';

  String Custom_Font = 'Custom Font';
  String Supported_formats = 'Supported formats';
  String Font = 'Font';
  String Thumbnail_corners = 'Thumbnail corners';
  String Cover_corners = 'Cover corners';
  String Pick_color = 'Pick color';

  // Sync
  String Deactivate = 'Deactivate';
  String Activate = 'Activate';
  String Connecting = 'Connecting...';
  String Accept = 'Accept';
  String Pair = 'Pair';
  String Unpair = 'Unpair';
  String Retry = 'Retry';
  String Preparation = 'Preparation';

  String Synchronize = 'Synchronize';
  String Download_files_from_partners_device =
      'Download files from partner\'s device';
  String Clean = 'Clean';
  String Delete_extra_files_on_this_device =
      'Delete extra files on this device';

  String Error = 'Error';
  String Errors = 'Errors';

  String No_network_connection = 'No network connection';
  String IP_address_not_found = 'IP address not found';
  String Network_unreachable = 'Network unavailable';
  String Connect_to_the_network_and_press_Retry =
      'Connect to the network and press "Retry"';
  String phrase__bad_activation =
      'An error occurred during activation. Make sure you have a network connection and the IP address is correct';
  String Unknown_error = 'Unknown error';

  String Mine = 'Mine';
  String Partner = 'Partner';
  String Partners = "Partner's";
  String Leave_as_is = 'Leave as is';
  String phrase__Playlist_conflict =
      'There was a playlist conflict.\nWhich playlists should be kept?';
  String Error_from_partner = 'Error from partner';

  String Unable_to_access_path = 'Unable to access path';
  String Path_not_found = 'Path not found';
  String File_system_error = 'File system error';
  String Unable_to_read_directory = 'Unable to read directory';
  String Undefind_error = 'Undefined error';

  String Sending_files = 'Sending files';
  String Downloading_files = 'Downloading files';
  String Cleaning_files = 'Cleaning files';

  String About_modes = 'About modes';
  String File_sharing_with_a_partner = 'File sharing with a partner';
  String Downloading_file_from_partner = 'Downloading file from partner';
  String Removing_extra_files_that_the_partner_does_not_have =
      'Removing extra files that the partner does not have';
  String Remove_extra_files_that_the_partner_does_not_have__q =
      'Remove extra files that the partner does not have?';
  String See = 'See';

  String phrase__mine =
      'The partner will have the same version of playlists that you have';
  String phrase__partner =
      'You will have the same version of playlists that the partner has';
  String phrase__as_is = 'Conflicting playlists will not be exchanged';

  String phrase__no_active_devices_to_pair_with =
      'There are no active devices for pairing. Activate sync on another device.';

  // Plugins
  String Server_address = 'Server address';
  String Download_plugins = 'Download a plugins';
  String Network_error = 'Network error';

  String Install_from_zip_file = 'Install from zip file';
  String Install_from_the_server = 'Install from the server';
  String Error_occurred_while_extracting_zip_archive =
      'An error occurred while extracting the zip archive';
  String Error_occurred_while_downloading_plugin =
      'An Error occurred while downloading the plugin';
  String Error_occurred_while_deleting_plugin =
      'Error occured while deleting the plugin';
  String phrase__Plugin_successfully_installed =
      'The plugin has been installed successfully';
  String Failed_downloading_plugin = 'Failed to load plugin';
  String Plugin_not_found = 'Plugin not found';
  String The_plugin_has_been_reloaded = 'The plugin has been reloaded';

  String My_plugins = 'My plugins';
  String Home = 'Home';
  String plugins__genetive = 'plugins';
  String Add_url = 'Add url';
  String Url = 'Url';

  String Title = 'Title';
  String Long_title = 'Long title';
  String Description = 'Descrtiption';
  String Version = 'Version';
  String Minimum_app_version = 'Minimum app version';
  String Permissions = 'Permissions';
  String Homepage = 'Homepage';
  String Repository = 'Repository';
  String Author = 'Author';
  String Published_at = 'Published at';
  String Unpacked_size = 'Unpacked size';
  String Deleted_User = 'Deleted User';

  String Approved_by = 'Approved by';

  String phrase__plugin_welcome = 'Welcome to the plugins (extensions) page.';
  String Warning = 'Warning';
  String phrase__disclaimer =
      '''Plugins are small programs that expand the music player's capabilities:
- add new music sources;
- provide lyrics, etc.
The music player developer is not responsible for plugins. There is no guarantee of their quality or security. Use only trusted plugins.''';
  // String Ive_read_and_understood = 'I\'ve read and understood';
  String Plugin_settings = 'Plugin settings';
  String Automatically_load_the_home_page_when_entering_the_plugins_page =
      'Automatically load the home page when entering the plugins page';
  String Automatic_check_for_plugin_updates =
      'Automatic check for plugin updates';
  String This_message_will_not_appear_again =
      'This message will not appear again';
  String Continue = 'Continue';

  // FsSource
  String Tracks = 'Tracks';
  String Playlists = 'Playlists';
  String Artists = 'Artists';
  String Albums = 'Albums';

  String songs = 'songs';

  String Favourites = 'Favourites';
  String phrase__only_allowed = 'Only letters, spaces and "-", "_" are allowed';

  String Autoplay = 'Autoplay';
}

class RuLang implements Lang {
  String type_ = 'russian';
  String code_ = 'ru';
  // Sidebar
  String Settings = 'Настройки';
  String Appearance = 'Внешний вид';
  String Sync = 'Синхронизация';
  String Plugins = 'Плагины';
  String Files = 'Файлы';
  String Selected_folder = 'Выбранная папка';
  String Search = 'Поиск';

  // Music item
  String Unknown_Title = 'Неизвестное Название';
  String Unknown_Artist = 'Неизвестный Исполнитель';
  String Unknown_Album = 'Неизвестный Альбом';
  String Unknown_Year = 'Неизвестный Год';
  String Unknown_Track = 'Неизвестный Трек';
  String Unknown_Genre = 'Неизвестный Жанр';

  // Dialogs
  String Add_to_queue = 'Добавить в очередь';
  String Play_next = 'Включить следующим';
  String Clear_queue = 'Очистить очередь';
  String To_artist = 'К исполнителю';
  String Like = 'Нравится';
  String Dislike = 'Не нравится';
  String Add_to_playlist = 'Добавить в плейлист';
  String Delete = 'Удалить';
  String Delete_playlist = 'Удалить плейлист';
  String Remove_from_playlist = 'Убрать из плейлиста';
  String Modify_playlist = 'Изменить плейлист';
  String New_playlist = 'Новый плейлист';
  String Download = 'Скачать';
  String Downloading = 'Загрузка';
  String Music_folder_not_specified = 'Папка с музыкой не указана';
  String The_file_already_exists = 'Файл {} уже существует';
  String Overwrite_it = 'Перезаписать';
  String Create_a_new_file_named = 'Создать новый файл с именем';

  String Delete_this_song = 'Удалить эту песню?';
  String Delete_these_songs = 'Удалить эти песни?';
  String Delete__q = 'Удалить?';

  String Name = 'Название';
  String Actions = 'Действия';
  String Queue_is_empty = 'Очередь пуста';
  String Queue = 'Очередь';
  String Lyrics = 'Текст';

  // Notifications
  String saved_from_cache = 'сохранено из кэша';
  String already_loading = 'уже загружается';
  String Failed_to_load = 'Не удалось загрузить';
  String The_item_has_already_been_removed = 'Элемент уже удален';
  String No_data = 'Нет данных';
  String downloaded = 'загружено';
  String Error_occurred = 'Произошла ошибка';
  String Failed_to_load_folder = 'Не удалось загрузить папку';

  // Guards
  String Select_the_music_folder = 'Выберите папку с музыкой';
  String Grant_audio_permission = 'Предоставите разрешение для аудио';
  String Grant_access_to_storage = 'Предоставить доступ к хранилищу';
  String Grant = 'Предоставить';
  String Reload = 'Перезагрузить';
  String Use_default_music_folder = 'Использовать папку с музыкой по умолчанию';
  String Or = 'Или';

  // Buttons
  String Ok = 'Ok';
  String Submit = 'Подтвердить';
  String Save = 'Сохранить';
  String Save_palette = 'Сохранить палитру';
  String Cancel = 'Отменить';
  String Reset = 'Сбросить';
  String Choose = 'Выбрать';
  String Yes = 'Да';
  String No = 'Нет';

  // Settings
  String Folder_with_music = 'Папка с музыкой';
  String Cache = 'Кэш';
  String Language = 'Язык';
  String Key_bindings = 'Привязка клавиш';
  String Volume = 'Громкость';
  String Equalizer = 'Эквалайзер';
  String Licenses = 'Лицензии';
  String For_developers = 'Для разработчиков';
  String Clear = 'Очистить';
  String Cache_cleared = 'Кэш очищен';
  String phrase__cache_errored = 'Что-то пошло не так при очистке кэша';

  String Quick_pick = 'Быстрый выбор';
  String Music_folder = 'Папка Музыки';
  String Downloads_folder = 'Папка Загрузок';
  String tracks__genetive = 'треков';
  String phrase__no_music_in_folder = '''В папке "{}" нет музыкальных файлов.
Пожалуйста, добавьте музыку в эту папку или выберите другую папку в Настройках.''';

  String Enabled = 'Включено';

  // Key bindings
  String Action = 'Действие';
  String Keys = 'Клавиши';
  String Press_keys = 'Нажмите клавиши';
  String Conflicts_have_occurred = 'Возникли конфликты';
  String will_be_reset_when_you_press_save =
      'будет сброшено при нажатии "Сохранить"';

  String kb__toggle_playback = 'Воспроизведение/пауза';
  String kb__play_prev = 'Воспроизвести предыдущее';
  String kb__play_next = 'Воспроизвести следующее';
  String kb__shuffle = 'Перемещать';
  String kb__toggle_repeat = 'Переключить повтор';
  String kb__show_current_item_dialog = 'Показать диалог текущего элемента';
  String kb__choose = 'Выбрать элемент';
  String kb__focus_up = 'Фокус вверх';
  String kb__focus_down = 'Фокус вниз';
  String kb__to_bottom = 'Вниз';
  String kb__to_top = 'Вверх';
  String kb__focus_left_pane = 'Фокус на левую панeль';
  String kb__focus_right_pane = 'Фокус на правую панeль';
  String kb__to_prev_tab = 'Предыдущая вкладка';
  String kb__to_next_tab = 'Следующая вкладка';
  String kb__back = 'Назад';
  String kb__show_item_dialog = 'Показать диалог элемента';
  String kb__focus_search = 'Фокус на поле поиска';
  String kb__unfocus = 'Убрать фокус';
  String kb__prev_suggestion = 'Следующее предложение поиска';
  String kb__next_suggestion = 'Предыдущее предложение поиска';

  // Appearance
  String Color_Palettes = 'Цветовые палитры';
  String Colors = 'Цвета';

  String Text = 'Текст';
  String Background = 'Фон';
  String Subtitle = 'Подзаголовок';
  String Primary = 'Основной';
  String Accent = 'Акцент';

  String Dynamic_theme = 'Динамическая тема';
  String Off = 'Выкл.';
  String Only_on_the_playback_page = 'Только на странице воспроизведения';
  String Everywhere = 'Везде';

  String Custom_Font = 'Пользовательский шрифт';
  String Supported_formats = 'Поддерживаемые форматы';
  String Font = 'Шрифт';
  String Thumbnail_corners = 'Углы миниатюры';
  String Cover_corners = 'Углы обложки';
  String Pick_color = 'Выбрать цвет';

  // Sync
  String Deactivate = 'Выключить';
  String Activate = 'Активировать';
  String Connecting = 'Соединение...';
  String Accept = 'Принять';
  String Pair = 'Подключиться';
  String Unpair = 'Отключитсья';
  String Retry = 'Повторить';
  String Preparation = 'Подготовка';

  String Synchronize = 'Синхронизировать';
  String Download_files_from_partners_device =
      'Скачать файлы с устройства партнера';
  String Clean = 'Очистить';
  String Delete_extra_files_on_this_device =
      'Удалить лишние файлы на этом устройстве';

  String Error = 'Ошибка';
  String Errors = 'Ошибки';

  String No_network_connection = 'Нет интернет-соединения';
  String IP_address_not_found = 'IP адрес не найден';
  String Network_unreachable = 'Сеть недоступна';
  String Connect_to_the_network_and_press_Retry =
      'Подключитесь к сети и нажмите "Повторить"';
  String phrase__bad_activation =
      'Произошла ошибка при активации. Убедитесь, что есть подключение к сети, а IP адрес выбран правильно';
  String Unknown_error = 'Неизвестная ошибка';

  String Mine = 'Мои';
  String Partner = 'Партнер';
  String Partners = 'Партнера';
  String Leave_as_is = 'Оставить как есть';
  String phrase__Playlist_conflict =
      'Возник конфликт плейлистов.\nКакие плейлисты следует сохранить?';
  String Error_from_partner = 'Ошибка от партнера';

  String Unable_to_access_path = 'Невозможно получить доступ к пути';
  String Path_not_found = 'Путь не найден';
  String File_system_error = 'Ошибка файловой системы';
  String Unable_to_read_directory = 'Невозможно прочитать каталог';
  String Undefind_error = 'Неизвестная ошибка';

  String Sending_files = 'Отправка файлов';
  String Downloading_files = 'Скачивание файлов';
  String Cleaning_files = 'Очистка файлов';

  String About_modes = 'О режимах';
  String File_sharing_with_a_partner = 'Обмен файлами с партнером';
  String Downloading_file_from_partner = 'Загрузка файлов от партнера';
  String Removing_extra_files_that_the_partner_does_not_have =
      'Удаление лишних файлов, которых нет у партнера';
  String Remove_extra_files_that_the_partner_does_not_have__q =
      'Удалить лишние файлы, которых нет у партнера?';
  String See = 'См.';

  String phrase__mine = 'У партнера будет та же версия плейлистов, что и у Вас';
  String phrase__partner =
      'У Вас будет та же версия плейлистов, что и у партнера';
  String phrase__as_is = 'Обмен конфликтующих плейлистов производится не будет';

  String phrase__no_active_devices_to_pair_with =
      'Нет активных устройств для сопряжения. Активируйте синхронизацию на другом устройстве.';

  // Plugins
  String Server_address = 'Адрес сервера';
  String Download_plugins = 'Загрузить плагины';
  String Network_error = 'Oшибка сети';

  String Install_from_zip_file = 'Установить из архива';
  String Install_from_the_server = 'Установить с сервера';
  String Error_occurred_while_extracting_zip_archive =
      'Произошла ошибка при извлечении zip архива';
  String Error_occurred_while_downloading_plugin =
      'Произошла ошибка при загрузке плагина';
  String Error_occurred_while_deleting_plugin =
      'Произошла ошибка при удалении плагина';
  String phrase__Plugin_successfully_installed = 'Плагин успешно установлен';
  String Failed_downloading_plugin = 'Не удалось загрузить плагин';
  String Plugin_not_found = 'Плагин не найден';
  String The_plugin_has_been_reloaded = 'Плагин перезагружен';

  String My_plugins = 'Мои плагины';
  String Home = 'Главная';
  String plugins__genetive = 'плагинов';
  String Add_url = 'Добавить url';
  String Url = 'Url';

  String Title = 'Заголовок';
  String Long_title = 'Расширенный заголовок';
  String Description = 'Описание';
  String Version = 'Версия';
  String Minimum_app_version = 'Минимальная версия приложения';
  String Permissions = 'Разрешения';
  String Homepage = 'Домашная страница';
  String Repository = 'Репозиторий';
  String Author = 'Автор';
  String Published_at = 'Опубликовано';
  String Unpacked_size = 'Распакованный размер';
  String Deleted_User = 'Удаленный пользователь';

  String Approved_by = 'Одобрено';

  String phrase__plugin_welcome =
      'Добро пожаловать на страницу плагинов (расширений).';
  String Warning = 'Предупреждение';
  String phrase__disclaimer =
      'Плагины — это небольшие программы, которые расширяют возможности плеера:\n- добавляют новые источники музыки;\n- предоставляют тексты для песен и т.п.\nРазработчик плеера не несёт ответственность за плагины. Нет гарантии их качества и безопасности. Используйте только те плагины, которым доверяете.';
  // String Ive_read_and_understood = 'Я прочитал и понял';
  String Plugin_settings = 'Настройки плагинов';
  String Automatically_load_the_home_page_when_entering_the_plugins_page =
      'Автоматически загружать главную страницу при входе на страницу плагинов';
  String Automatic_check_for_plugin_updates =
      'Автоматически проверять обновления плагинов';
  String This_message_will_not_appear_again =
      'Это сообщение не будет показываться повторно';
  String Continue = 'Продолжить';

  // FsSource
  String Tracks = 'Треки';
  String Playlists = 'Плейлисты';
  String Artists = 'Исполнители';
  String Albums = 'Альбомы';

  String songs = 'композиций';

  String Favourites = 'Избранное';
  String phrase__only_allowed = 'Разрешены только буквы, пробелы и "-", "_"';

  String Autoplay = 'Автовоспроизведение';
}

Lang lang = EnLang();
