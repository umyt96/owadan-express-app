import 'app_strings_en.dart';

/// Строки интерфейса на русском, туркменском и английском.
///
/// Туркменские переводы там, где это возможно, взяты из настоящего файла
/// переводов сайта (locale/tk/LC_MESSAGES/django.po), а не придуманы —
/// поэтому формулировки совпадают с сайтом owadanexpress.com.tm.
///
/// Английские строки хранятся отдельно в app_strings_en.dart.
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _dict = {
    // Нижнее меню
    'nav_home': {'ru': 'Главная', 'tk': 'Esasy'},
    'nav_categories': {'ru': 'Категории', 'tk': 'Kategoriýa'},
    'nav_favorites': {'ru': 'Избранное', 'tk': 'Halanlarym'},
    'nav_cart': {'ru': 'Корзина', 'tk': 'Sebedim'},
    'nav_profile': {'ru': 'Профиль', 'tk': 'Profilim'},

    // Общее
    'app_name': {'ru': 'Owadan Express', 'tk': 'Owadan Express'},
    'home_welcome': {
      'ru': 'Найдите то, что радует',
      'tk': 'Göwnüňizden turýan harydy tapyň',
    },
    'home_tagline': {
      'ru': 'Любимые покупки в одном месте',
      'tk': 'Halan harytlaryňyz bir ýerde',
    },
    'search_hint': {'ru': 'Поиск товаров', 'tk': 'Haryt gözletmek'},
    'search_results': {'ru': 'Результаты поиска', 'tk': 'Gözlegiň netijesi'},
    'found_count': {'ru': 'Найдено', 'tk': 'Tapyldy'},
    'search_prompt': {
      'ru': 'Введите название товара и нажмите Enter или на значок поиска',
      'tk': 'Harydyň adyny ýazyň we Enter ýa-da gözleg nyşanyna basyň',
    },
    'nothing_found': {
      'ru': 'По вашему запросу ничего не найдено.',
      'tk': 'Siziň gözlegiňiz boýunça hiçzat tapylmady.',
    },
    'loading': {'ru': 'Загрузка...', 'tk': 'Ýüklenýär...'},
    'error': {'ru': 'Ошибка', 'tk': 'Ýalňyşlyk'},
    'save': {'ru': 'Сохранить', 'tk': 'Goşmak'},
    'cancel': {'ru': 'Отмена', 'tk': 'Ýatyrmak'},
    'delete': {'ru': 'Удалить', 'tk': 'Pozmak'},
    'send': {'ru': 'Отправить', 'tk': 'Ýollamak'},

    // Каталог
    'categories_title': {'ru': 'Категории', 'tk': 'Kategoriýa'},
    'new_items_title': {'ru': 'Новинки', 'tk': 'Täze'},
    'recommended_title': {'ru': 'Рекомендуемые', 'tk': 'Maslahat berilýän'},
    'you_may_also_like': {
      'ru': 'Вам также может понравиться',
      'tk': 'Sizi şular hem gyzyklandyryp biler'
    },
    'see_all': {'ru': 'Все', 'tk': 'Hemmesi'},
    'brands_title': {'ru': 'Бренды', 'tk': 'Brentlar'},
    'all_products': {'ru': 'Все товары', 'tk': 'Ähli harytlar'},
    'category_empty': {'ru': 'Категория пуста', 'tk': 'Kategoriýa boş'},
    'empty_categories_title': {
      'ru': 'Категорий пока нет',
      'tk': 'Entek kategoriýa ýok'
    },
    'empty_categories_body': {
      'ru': 'Загляните позже — новые разделы скоро появятся.',
      'tk': 'Soňrak täzeden göz aýlaň — täze bölümler ýakynda goşular.',
    },
    'browse_categories': {
      'ru': 'Смотреть категории',
      'tk': 'Kategoriýalara seret'
    },
    'decrease': {'ru': 'Уменьшить количество', 'tk': 'Sanyny azalt'},
    'increase': {'ru': 'Увеличить количество', 'tk': 'Sanyny artdyr'},
    'empty_cart_body': {
      'ru': 'Выберите понравившиеся товары, и они появятся здесь.',
      'tk': 'Halan harytlaryňyzy saýlaň, olar şu ýerde peýda bolar.',
    },
    'cart_login_hint': {
      'ru': 'Войдите, чтобы увидеть товары в корзине.',
      'tk': 'Sebetdäki harytlary görmek üçin hasaba giriň.',
    },
    'empty_favorites_body': {
      'ru': 'Сохраняйте понравившиеся товары, чтобы легко найти их снова.',
      'tk': 'Halan harytlaryňyzy soň aňsat tapmak üçin belläň.',
    },
    'empty_orders_body': {
      'ru': 'После оформления заказа его статус появится здесь.',
      'tk': 'Sargyt bereniňizden soň onuň ýagdaýy şu ýerde görkeziler.',
    },
    // По количеству товара: можно ли сейчас купить.
    'out_of_stock': {'ru': 'Нет в наличии', 'tk': 'Gutardy'},

    // Товар
    'add_to_cart': {'ru': 'Добавить в корзину', 'tk': 'Sebede goşmak'},
    'select_size_required': {
      'ru': 'Пожалуйста, выберите размер',
      'tk': 'Haýyş, ölçegini saýlaň'
    },
    'select_color_required': {
      'ru': 'Пожалуйста, выберите цвет',
      'tk': 'Haýyş, reňkini saýlaň'
    },
    'add_to_cart_short': {'ru': 'В корзину', 'tk': 'Sebede goşmak'},
    'size': {'ru': 'Размер', 'tk': 'Ölçegi'},
    'color': {'ru': 'Цвет', 'tk': 'Reňki'},
    'quantity': {'ru': 'Количество', 'tk': 'Sany'},
    'description': {'ru': 'Описание', 'tk': 'Düşündirilişi'},
    'delivery': {'ru': 'Доставка', 'tk': 'Eltip bermek'},
    'days': {'ru': 'дней', 'tk': 'gün'},
    'cargo_included': {
      'ru': 'Карго включено в сумму',
      'tk': 'Kargo bahasyna girýär'
    },
    'share': {'ru': 'Поделиться', 'tk': 'Paýlaşmak'},
    // Корзина / избранное
    'select_all': {'ru': 'Выбрать все', 'tk': 'Hemmesini saýlamak'},
    'remove_from_cart_confirm': {
      'ru': 'Удалить выбранные товары из корзины?',
      'tk': 'Saýlanan harytlary sebetden pozmalymy?',
    },
    'selected': {'ru': 'Выбрано', 'tk': 'Saýlandy'},
    'select': {'ru': 'Выбрать', 'tk': 'Saýlamak'},
    'delete_selected': {'ru': 'Удалить выбранные', 'tk': 'Saýlananlary pozmak'},
    'clear_favorites': {
      'ru': 'Очистить избранное',
      'tk': 'Halanlary arassalamak'
    },
    'clear_favorites_confirm': {
      'ru': 'Удалить все товары из избранного?',
      'tk': 'Ähli harytlary halanlardan pozmalymy?',
    },
    'favorites_login_hint': {
      'ru': 'Войдите, чтобы просмотреть избранное',
      'tk': 'Halanlary görmek üçin hasaba giriň',
    },
    'favorites_empty': {
      'ru': 'Пока нет избранных товаров',
      'tk': 'Entek halanan haryt ýok'
    },
    // Сообщения клиентов (суперпользователь)
    'client_messages': {
      'ru': 'Сообщения клиентов',
      'tk': 'Müşderileriň hatlary'
    },
    'admin_reviews': {'ru': 'Отзывы', 'tk': 'Teswirler'},
    // Управление товарами (персонал)
    'manage_products': {'ru': 'Товары', 'tk': 'Harytlar'},
    // Справочники суперпользователя (admin_catalog_screen.dart)
    'add': {'ru': 'Добавить', 'tk': 'Goş'},
    'search': {'ru': 'Поиск', 'tk': 'Gözleg'},
    'saved': {'ru': 'Сохранено', 'tk': 'Ýatda saklandy'},
    'delete_confirm': {
      'ru': 'Удалить эту запись?',
      'tk': 'Bu ýazgyny pozmalymy?'
    },
    'required_field': {'ru': 'Обязательное поле', 'tk': 'Hökmany meýdan'},
    'invalid_number': {'ru': 'Введите число', 'tk': 'San giriziň'},
    'choose_photo': {'ru': 'Выбрать фото', 'tk': 'Surat saýla'},
    'remove_photo': {'ru': 'Убрать фото', 'tk': 'Suraty aýyr'},
    'coupons': {'ru': 'Купоны', 'tk': 'Kuponlar'},
    'contacts_admin': {
      'ru': 'Наши контакты',
      'tk': 'Biziň habarlaşmak maglumatlarymyz'
    },
    'categories_admin': {'ru': 'Категории', 'tk': 'Kategoriýalar'},
    'subcategories_admin': {'ru': 'Подкатегории', 'tk': 'Bölümçeler'},
    'brands_admin': {'ru': 'Бренды', 'tk': 'Brendler'},
    'currency_admin': {'ru': 'Валюта', 'tk': 'Walýuta'},
    'filter_all': {'ru': 'Все', 'tk': 'Hemmesi'},
    'filter_hidden': {'ru': 'Скрытые', 'tk': 'Gizlenen'},
    'filter_out_of_stock': {'ru': 'Нет на складе', 'tk': 'Ammarda ýok'},
    'add_product': {'ru': 'Добавить товар', 'tk': 'Haryt goşmak'},
    'edit_product': {'ru': 'Изменить товар', 'tk': 'Harydy üýtgetmek'},
    'delete_product': {'ru': 'Удалить товар', 'tk': 'Harydy pozmak'},
    'delete_product_confirm': {
      'ru': 'Удалить этот товар вместе с фото? Действие необратимо.',
      'tk':
          'Bu harydy suratlary bilen pozmalymy? Bu amaly yzyna gaýtaryp bolmaz.',
    },
    'product_created': {'ru': 'Товар добавлен', 'tk': 'Haryt goşuldy'},
    'product_saved': {
      'ru': 'Изменения сохранены',
      'tk': 'Üýtgeşmeler ýatda saklandy'
    },
    'product_deleted': {'ru': 'Товар удалён', 'tk': 'Haryt pozuldy'},
    'search_product_hint': {
      'ru': 'Поиск по названию или ID',
      'tk': 'Ady ýa-da ID boýunça gözleg'
    },
    'published': {'ru': 'Опубликован', 'tk': 'Çap edildi'},
    'not_published': {'ru': 'Скрыт', 'tk': 'Gizlenen'},
    'published_hint': {
      'ru': 'Если выключить, товар не будет виден клиентам',
      'tk': 'Öçürilse, haryt müşderilere görünmez',
    },
    'photos': {'ru': 'Фото', 'tk': 'Suratlar'},
    'main_photo': {'ru': 'Главное фото', 'tk': 'Esasy surat'},
    'change_photo': {'ru': 'Заменить', 'tk': 'Çalyşmak'},
    'extra_photos': {'ru': 'Дополнительные фото', 'tk': 'Goşmaça suratlar'},
    'from_gallery': {'ru': 'Из галереи', 'tk': 'Galereýadan'},
    'from_camera': {'ru': 'Сфотографировать', 'tk': 'Surata almak'},
    'main_info': {'ru': 'Основное', 'tk': 'Esasy maglumat'},
    'title_ru': {'ru': 'Название (русский)', 'tk': 'Ady (rus dilinde)'},
    'title_tk': {'ru': 'Название (туркменский)', 'tk': 'Ady (türkmen dilinde)'},
    'title_en': {'ru': 'Название (английский)', 'tk': 'Ady (iňlis dilinde)'},
    'subcategory': {'ru': 'Подкатегория', 'tk': 'Bölümçe'},
    'brand': {'ru': 'Бренд', 'tk': 'Brend'},
    'no_brand': {'ru': 'Без бренда', 'tk': 'Brendsiz'},
    'price_section': {'ru': 'Цена и наличие', 'tk': 'Baha we bar bolşy'},
    'price_cny': {'ru': 'Цена', 'tk': 'Bahasy'},
    'discount_price_cny': {
      'ru': 'Цена со скидкой',
      'tk': 'Arzanladyşly bahasy'
    },
    'for_customers': {'ru': 'для покупателей', 'tk': 'müşderiler üçin'},
    'delivery_days': {'ru': 'Срок доставки (дней)', 'tk': 'Eltip bermek (gün)'},
    'sizes_and_colors': {'ru': 'Размеры и цвета', 'tk': 'Ölçegler we reňkler'},
    'size_prices': {'ru': 'Цены по размерам', 'tk': 'Ölçeglere görä bahalar'},
    'size_prices_hint': {
      'ru': 'Пусто — для этого размера действует цена товара.',
      'tk': 'Boş bolsa — bu ölçeg üçin harydyň bahasy hasaplanýar.',
    },
    'size_discount_too_big': {
      'ru': 'Цена со скидкой размера должна быть меньше его цены',
      'tk': 'Ölçegiň arzanladyşly bahasy onuň bahasyndan az bolmaly',
    },
    'not_selected': {'ru': 'Не выбрано', 'tk': 'Saýlanmadyk'},
    'description_ru': {
      'ru': 'Описание (русский)',
      'tk': 'Düşündiriş (rus dilinde)'
    },
    'description_tk': {
      'ru': 'Описание (туркменский)',
      'tk': 'Düşündiriş (türkmen dilinde)'
    },
    'description_en': {'ru': 'Описание (английский)', 'tk': 'Düşündiriş (iňlis dilinde)'},
    'description_format_note': {
      'ru':
          'Описание оформлено на сайте. Если его не менять, оформление сохранится; при изменении здесь оно станет простым текстом.',
      'tk':
          'Düşündiriş saýtda bezelen. Üýtgedilmese, bezegi saklanar; şu ýerde üýtgedilse, ýönekeý tekste öwrüler.',
    },
    'need_title': {
      'ru': 'Укажите название на русском',
      'tk': 'Rus dilinde adyny görkeziň'
    },
    'need_category': {'ru': 'Выберите подкатегорию', 'tk': 'Bölümçäni saýlaň'},
    'need_price': {'ru': 'Укажите цену', 'tk': 'Bahasyny görkeziň'},
    'need_main_photo': {
      'ru': 'Добавьте главное фото',
      'tk': 'Esasy suraty goşuň'
    },
    'discount_too_big': {
      'ru': 'Цена со скидкой должна быть меньше обычной цены',
      'tk': 'Arzanladyşly baha adaty bahadan pes bolmaly',
    },
    'uploading': {'ru': 'Загрузка', 'tk': 'Ýüklenýär'},
    'done': {'ru': 'Готово', 'tk': 'Taýýar'},
    'search_or_create': {
      'ru': 'Найти или создать',
      'tk': 'Gözleg ýa-da täze baha'
    },
    'create_new': {'ru': 'Создать', 'tk': 'Döretmek'},
    'new_color': {'ru': 'Новый цвет', 'tk': 'Täze reňk'},
    'average_rating': {'ru': 'Средняя оценка', 'tk': 'Ortaça baha'},
    'hidden_reviews': {'ru': 'Скрытые', 'tk': 'Gizlenen'},
    'search_reviews_hint': {
      'ru': 'Поиск: текст, клиент, товар',
      'tk': 'Gözleg: tekst, müşderi, haryt'
    },
    'review_visible': {'ru': 'Показан', 'tk': 'Görünýär'},
    'review_hidden': {'ru': 'Скрыт', 'tk': 'Gizlenen'},
    'delete_review': {'ru': 'Удалить отзыв', 'tk': 'Teswiri pozmak'},
    'delete_review_confirm': {
      'ru': 'Удалить этот отзыв вместе с фото? Действие необратимо.',
      'tk':
          'Bu teswiri suratlary bilen pozmalymy? Bu amaly yzyna gaýtaryp bolmaz.',
    },
    'review_deleted': {'ru': 'Отзыв удалён', 'tk': 'Teswir pozuldy'},
    'all_messages': {'ru': 'Все', 'tk': 'Hemmesi'},
    'unanswered': {'ru': 'Без ответа', 'tk': 'Jogapsyz'},
    'write_message': {'ru': 'Написать', 'tk': 'Ýazmak'},
    'reply_to': {'ru': 'Ответ:', 'tk': 'Jogap:'},
    'reply': {'ru': 'Ответить', 'tk': 'Jogap bermek'},
    'edit_reply': {'ru': 'Изменить ответ', 'tk': 'Jogaby üýtgetmek'},
    'new_badge': {'ru': 'Новое', 'tk': 'Täze'},
    'choose_recipient': {'ru': 'Выберите получателя', 'tk': 'Alyjyny saýlaň'},
    'send_to_all': {'ru': 'Отправить всем', 'tk': 'Hemmelere ibermek'},
    'send_to_all_confirm': {
      'ru': 'Сообщение получат все клиенты. Отправить?',
      'tk': 'Habary ähli müşderiler alar. Ibermelimi?',
    },
    'one_client': {'ru': 'Одному', 'tk': 'Birine'},
    'all_clients': {'ru': 'Всем', 'tk': 'Hemmelere'},
    'search_client': {'ru': 'Поиск клиента', 'tk': 'Müşderi gözlemek'},
    'in_stock': {'ru': 'Доступен', 'tk': 'Bar'},
    // Галочка "Есть в наличии" у товара (Item.in_stock).
    'update_downloaded': {
      'ru': 'Обновление загружено',
      'tk': 'Täzelenme ýüklendi'
    },
    'update_restart': {'ru': 'Перезапустить', 'tk': 'Täzeden aç'},
    'update_available_title': {
      'ru': 'Доступно обновление',
      'tk': 'Täzelenme elýeterli'
    },
    'update_available_body': {
      'ru':
          'Вышла новая версия Owadan Express. Обновите приложение, чтобы получить новые возможности и исправления.',
      'tk':
          'Owadan Express-iň täze wersiýasy çykdy. Täze mümkinçilikler we düzedişler üçin programmany täzeläň.',
    },
    'update_now': {'ru': 'Обновить', 'tk': 'Täzele'},
    'update_later': {'ru': 'Позже', 'tk': 'Soňra'},
    'stock_yes': {'ru': 'Есть в наличии', 'tk': 'Nagt bar'},
    'stock_no': {'ru': 'Нет в наличии', 'tk': 'Nagt ýok'},
    'stock_switch_hint': {
      'ru':
          'Снимите, если товара сейчас нет на складе — купить его всё равно можно',
      'tk': 'Haryt häzir ammarda ýok bolsa aýyryň — satyn alyp bolýar',
    },
    'filters': {'ru': 'Фильтры', 'tk': 'Filtrler'},
    'price_range': {'ru': 'Диапазон цены', 'tk': 'Baha aralygy'},
    'price_from': {'ru': 'От', 'tk': 'Başlangyç'},
    'price_to': {'ru': 'До', 'tk': 'Ahyrky'},
    'category': {'ru': 'Категория', 'tk': 'Kategoriýa'},
    'reset': {'ru': 'Сбросить', 'tk': 'Arassalamak'},
    'drawer_home': {'ru': 'Главная страница', 'tk': 'Baş sahypa'},
    'drawer_all': {'ru': 'Все', 'tk': 'Hemmesi'},
    'drawer_sale': {'ru': 'Скидки', 'tk': 'Arzanladyşlar'},
    'drawer_in_stock': {'ru': 'В наличии', 'tk': 'Nagt bar'},
    'location_title': {'ru': 'Местоположение (необязательно)', 'tk': 'Ýerleşýän ýer (hökmany däl)'},
    'location_hint': {'ru': 'Курьеру будет проще найти вас.', 'tk': 'Kurýer sizi aňsat tapar.'},
    'location_detect': {'ru': 'Определить по GPS', 'tk': 'GPS boýunça kesgitle'},
    'location_detecting': {'ru': 'Определяем…', 'tk': 'Kesgitlenýär…'},
    'location_refresh': {'ru': 'Обновить', 'tk': 'Täzele'},
    'location_added': {'ru': 'Местоположение добавлено', 'tk': 'Ýerleşýän ýer goşuldy'},
    'location_remove': {'ru': 'Убрать', 'tk': 'Aýyr'},
    'location_service_off': {'ru': 'Включите геолокацию (GPS) на телефоне.', 'tk': 'Telefonda GPS-i açyň.'},
    'location_denied': {'ru': 'Нет доступа к местоположению. Разрешите его в настройках.', 'tk': 'Ýerleşýän ýere rugsat ýok. Sazlamalarda rugsat beriň.'},
    'location_failed': {'ru': 'Не удалось определить местоположение. Попробуйте ещё раз.', 'tk': 'Ýerleşýän ýeri kesgitläp bolmady. Täzeden synanyşyň.'},
    'open_on_map': {'ru': 'На карте', 'tk': 'Kartada'},
    'filter_in_stock': {'ru': 'Только в наличии', 'tk': 'Diňe nagt bar harytlar'},
    'drawer_brands': {'ru': 'Бренды', 'tk': 'Brendler'},
    'drawer_about': {'ru': 'О нас', 'tk': 'Biz barada'},
    'drawer_contacts': {'ru': 'Контакты', 'tk': 'Habarlaşmak'},
    'drawer_privacy': {
      'ru': 'Политика конфиденциальности',
      'tk': 'Gizlinlik syýasaty'
    },
    'how_to_order_title': {
      'ru': 'Как сделать заказ',
      'tk': 'Sargydy nädip bermeli'
    },
    'order_guide_steps': {'ru': 'шагов', 'tk': 'ädim'},
    'order_guide_title': {
      'ru': 'От выбора до заказа',
      'tk': 'Saýlamakdan sargyda çenli',
    },
    'order_guide_intro': {
      'ru': 'Всё просто — следуйте этим шагам.',
      'tk': 'Bu ädimleri ýerine ýetirip, aňsat sargyt beriň.',
    },
    'privacy_open_hint': {
      'ru': 'Полный текст политики конфиденциальности доступен на сайте.',
      'tk': 'Gizlinlik syýasatynyň doly teksti saýtda elýeterli.',
    },
    'call_admin': {'ru': 'Позвонить', 'tk': 'Jaň etmek'},
    'chat_admin': {'ru': 'Написать в чат', 'tk': 'Çata ýazmak'},
    'reviews': {'ru': 'Отзывы клиентов', 'tk': 'Müşderileriň teswirleri'},
    'no_reviews': {
      'ru': 'Пока нет отзывов — будьте первым!',
      'tk': 'Entäk müşderiler teswirler galdyranok',
    },
    'leave_review': {'ru': 'Оставить отзыв', 'tk': 'Teswir galdyryň'},
    'add_review': {'ru': 'Добавить отзыв', 'tk': 'Teswir galdyryň'},
    'review_hint': {
      'ru': 'Поделитесь впечатлением о товаре...',
      'tk': 'Haryt barada pikiriňizi paýlaşyň...'
    },
    'add_photos': {'ru': 'Добавить фото', 'tk': 'Surat goşmak'},
    'review_thanks': {
      'ru': 'Спасибо за отзыв!',
      'tk': 'Teswiriňiz üçin sag boluň!'
    },
    'your_review': {'ru': 'Ваш отзыв', 'tk': 'Siziň teswiriňiz'},
    'login_to_review': {
      'ru': 'Войдите, чтобы оставить отзыв',
      'tk': 'Teswiriňizi galdyrmak üçin girişi geçmek zerur',
    },
    'login_now': {'ru': 'Войти сейчас', 'tk': 'Häzir hasaba girmek'},
    'contact_admin': {
      'ru': 'Обращение к администратору',
      'tk': 'Administratora ýüz tutmak'
    },
    'chat_empty_hint': {
      'ru': 'Здесь будет ваша переписка с администратором',
      'tk': 'Bu ýerde administrator bilen ýazyşmalaryňyz görkeziler',
    },
    'type_message_hint': {
      'ru': 'Введите ваше сообщение...',
      'tk': 'Habaryňyzy ýazyň...'
    },
    'administrator_label': {'ru': 'Администратор', 'tk': 'Administrator'},
    'question_about_product': {
      'ru': 'Ваш вопрос о товаре',
      'tk': 'Haryt barada soragyňyz'
    },
    'message_sent_to_admin': {
      'ru': 'Сообщение отправлено администратору',
      'tk': 'Habar administratora iberildi'
    },

    // Редактировать профиль
    'profile_updated': {'ru': 'Профиль обновлён', 'tk': 'Profil täzelendi'},
    'first_name': {'ru': 'Имя', 'tk': 'Ady'},
    'last_name': {'ru': 'Фамилия', 'tk': 'Familiýasy'},
    'email': {'ru': 'Email', 'tk': 'Email'},
    'phone_number': {'ru': 'Номер телефона', 'tk': 'Telefon belgisi'},
    'saving': {'ru': 'Сохраняем...', 'tk': 'Ýatda saklanýar...'},

    // История заказов
    'no_orders_yet': {
      'ru': 'У вас пока нет заказов',
      'tk': 'Sizde entek sargyt ýok'
    },
    'receipt': {'ru': 'Квитанция', 'tk': 'Kwitansiýa'},
    'thank_you_for_order': {
      'ru': 'Спасибо за ваш заказ, ',
      'tk': 'Sargydyňyz üçin sag boluň, '
    },
    'order_ref_code': {'ru': 'Код заказа', 'tk': 'Sargyt kody'},
    'code_copied': {'ru': 'Код скопирован', 'tk': 'Kod göçürildi'},
    'qty_short': {'ru': 'Кол-во', 'tk': 'Sany'},
    'order_date': {'ru': 'Дата', 'tk': 'Senesi'},
    'delivery_cost': {
      'ru': 'Стоимость доставки',
      'tk': 'Eltip bermegiň bahasy'
    },

    // Вернуть товар
    'return_intro_title': {
      'ru': 'Заявка на возврат',
      'tk': 'Yzyna tabşyrmak haýyşy',
    },
    'return_intro_body': {
      'ru': 'Укажите код заказа и причину возврата товара.',
      'tk': 'Sargyt koduny we harydy yzyna tabşyrmagyň sebäbini ýazyň.',
    },
    'return_request_sent': {
      'ru': 'Запрос на возврат отправлен',
      'tk': 'Gaýtarmak haýyşy iberildi'
    },
    'return_code_hint': {
      'ru': 'Код заказа можно найти в разделе "История заказов".',
      'tk': '"Sargytlaryň taryhy" bölüminde sargyt kodyny tapyp bilersiňiz.',
    },
    'order_code': {'ru': 'Код заказа', 'tk': 'Sargyt kody'},
    'return_reason_hint': {
      'ru': 'Опишите причину возврата',
      'tk': 'Gaýtarmagyň sebäbini ýazyň'
    },
    'return_reason_title': {
      'ru': 'Причина возврата',
      'tk': 'Yzyna tabşyrmagyň sebäbi',
    },
    'return_reason_helper': {
      'ru': 'Напишите, какой товар возвращаете и почему.',
      'tk': 'Haýsy harydy yzyna tabşyrýandygyňyzy we sebäbini düşündiriň.',
    },
    'sending': {'ru': 'Отправляем...', 'tk': 'Iberilýär...'},
    'send_return_request': {'ru': 'Отправить запрос', 'tk': 'Haýyşy ibermek'},

    // Изменить пароль
    'password_security_title': {
      'ru': 'Защитите свой аккаунт',
      'tk': 'Hasabyňyzy goraň',
    },
    'password_security_body': {
      'ru': 'Укажите текущий пароль, затем дважды введите новый.',
      'tk': 'Häzirki parolyňyzy, soňra täze paroly iki gezek ýazyň.',
    },
    'password_current_hint': {
      'ru': 'Введите пароль, который используете сейчас.',
      'tk': 'Häzir ulanýan parolyňyzy ýazyň.',
    },
    'password_new_hint': {
      'ru': 'Выберите новый пароль и повторите его для проверки.',
      'tk': 'Täze parol saýlaň we barlamak üçin ony gaýtadan ýazyň.',
    },
    'password_changed': {'ru': 'Пароль изменён', 'tk': 'Parol üýtgedildi'},
    'current_password': {'ru': 'Текущий пароль', 'tk': 'Häzirki parol'},
    'new_password': {'ru': 'Новый пароль', 'tk': 'Täze parol'},
    'passwords_dont_match': {
      'ru': 'Пароли не совпадают.',
      'tk': 'Parollar gabat gelmeýär.'
    },

    // Связаться с нами
    'message_sent': {'ru': 'Сообщение отправлено', 'tk': 'Habar iberildi'},
    'your_name': {'ru': 'Ваше имя', 'tk': 'Adyňyz'},
    'phone_or_email': {'ru': 'Телефон или email', 'tk': 'Telefon ýa-da email'},
    'message': {'ru': 'Сообщение', 'tk': 'Hatyňyz'},
    'write_to_us': {'ru': 'Написать нам', 'tk': 'Bize ýazyň'},
    'contact_hero_title': {
      'ru': 'Мы на связи',
      'tk': 'Biz siziň bilen habarlaşmaga taýýar',
    },
    'contact_hero_body': {
      'ru': 'Выберите удобный способ связи или отправьте сообщение ниже.',
      'tk': 'Habarlaşmagyň amatly usulyny saýlaň ýa-da aşakda habar iberiň.',
    },
    'contact_details_title': {
      'ru': 'Контактные данные',
      'tk': 'Habarlaşmak maglumatlary',
    },
    'contact_social_title': {
      'ru': 'Мы в соцсетях',
      'tk': 'Sosial ulgamlarda',
    },
    'contact_address': {'ru': 'Адрес', 'tk': 'Salgy'},
    'contact_phone': {'ru': 'Телефон', 'tk': 'Telefon'},
    'contact_form_intro': {
      'ru': 'Заполните форму, чтобы отправить нам сообщение.',
      'tk': 'Bize habar ibermek üçin blankany dolduryň.',
    },
    'contact_required': {
      'ru': 'Заполните это поле',
      'tk': 'Bu meýdany dolduryň',
    },
    'contact_info_empty': {
      'ru': 'Контактные данные пока недоступны.',
      'tk': 'Habarlaşmak maglumatlary häzir elýeterli däl.',
    },
    'contact_info_failed': {
      'ru': 'Не удалось загрузить контактные данные.',
      'tk': 'Habarlaşmak maglumatlaryny ýükläp bolmady.',
    },
    'contact_copied': {'ru': 'Скопировано', 'tk': 'Göçürildi'},
    'contact_optional': {'ru': 'Необязательно', 'tk': 'Hökmany däl'},
    'guest_profile_hint': {
      'ru': 'Войдите, чтобы видеть заказы, избранное и профиль',
      'tk': 'Sargytlary, halanlary we profili görmek üçin hasaba giriň',
    },

    // Корзина
    'cart_title': {'ru': 'Моя корзина', 'tk': 'Sebedim'},
    'cart_empty': {'ru': 'Ваша корзина пуста', 'tk': 'Siziň sebediňiz boş'},
    'total': {'ru': 'Итого', 'tk': 'Jemi'},
    'coupon': {'ru': 'Купон', 'tk': 'Kupon'},
    'promo_code': {'ru': 'Промо код', 'tk': 'Promo kod'},
    'apply': {'ru': 'Применить', 'tk': 'Ulanmak'},
    'checkout': {'ru': 'Оформить заказ', 'tk': 'Sargyt etmek'},

    // Оформление заказа
    'checkout_title': {
      'ru': 'Оформление заказа',
      'tk': 'Sargyt resmileşdirmek'
    },
    'shipping_address': {'ru': 'Адрес доставки', 'tk': 'Eltip berilmeli salgy'},
    'new_address': {'ru': 'Новый адрес', 'tk': 'Täze salgy'},
    'street_hint': {'ru': 'Город/этрап/улица', 'tk': 'Şäher/etrap/köçe'},
    'apartment_hint': {'ru': 'Дом/квартира', 'tk': 'Jaý/Otag'},
    'region_hint': {'ru': 'Регион', 'tk': 'Welaýat'},
    'phone_hint': {'ru': 'Номер телефона', 'tk': 'Telefon belgi'},
    'save_as_default': {
      'ru': 'Сохранить как основной адрес',
      'tk': 'Esasy salgy hökmünde ýatda saklamak',
    },
    'confirm_order': {'ru': 'Подтвердить заказ', 'tk': 'Sargydyňyzy tassyklaň'},
    'order_success': {
      'ru': 'Заказ оформлен!',
      'tk': 'Siziň sargydyňyz üstünlikli kabul edildi!',
    },
    'checkout_required_fields': {
      'ru': 'Заполните улицу, регион и номер телефона.',
      'tk': 'Köçäni, welaýaty we telefon belgisini dolduryň.',
    },
    'checkout_select_address': {
      'ru': 'Выберите адрес доставки.',
      'tk': 'Eltip berilmeli salgyny saýlaň.',
    },
    'checkout_contact_message': {
      'ru': 'Мы свяжемся с вами для подтверждения доставки.',
      'tk': 'Eltip bermegi tassyklamak üçin siziň bilen habarlaşarys.',
    },
    'checkout_processing': {
      'ru': 'Оформляем...',
      'tk': 'Sargyt resmileşdirilýär...'
    },
    'total_amount': {'ru': 'Сумма', 'tk': 'Jemi baha'},
    'ok': {'ru': 'ОК', 'tk': 'Bolýar'},

    // Аутентификация
    'login_title': {'ru': 'Вход', 'tk': 'Giriş'},
    'register_title': {'ru': 'Регистрация', 'tk': 'Agza bol'},
    'login_intro': {
      'ru': 'Войдите, чтобы сохранять любимые товары и следить за заказами.',
      'tk':
          'Halan harytlaryňyzy saklamak we sargytlaryňyzy yzarlamak üçin giriň.',
    },
    'register_intro': {
      'ru': 'Создайте аккаунт, чтобы покупки стали ещё удобнее.',
      'tk': 'Söwdany has amatly etmek üçin hasap dörediň.',
    },
    'auth_no_account': {
      'ru': 'Нет аккаунта?',
      'tk': 'Hasabyňyz ýokmy?',
    },
    'auth_have_account': {
      'ru': 'Уже есть аккаунт?',
      'tk': 'Hasabyňyz barmy?',
    },
    'email_optional': {
      'ru': 'Email (необязательно)',
      'tk': 'Email (hökmany däl)',
    },
    'phone_optional': {
      'ru': 'Номер телефона (необязательно)',
      'tk': 'Telefon belgisi (hökmany däl)',
    },
    'username': {'ru': 'Имя пользователя', 'tk': 'Ulanyjynyň ady'},
    'password': {'ru': 'Пароль', 'tk': 'Parol'},
    'register_confirm_password': {
      'ru': 'Повторите пароль',
      'tk': 'Paroly gaýtalaň',
    },
    'show_password': {'ru': 'Показать пароль', 'tk': 'Paroly görkez'},
    'hide_password': {'ru': 'Скрыть пароль', 'tk': 'Paroly gizle'},
    'confirm_password': {
      'ru': 'Повторите новый пароль',
      'tk': 'Paroly gaýtalaň'
    },
    'login_button': {'ru': 'Войти', 'tk': 'Giriş'},
    'register_button': {'ru': 'Зарегистрироваться', 'tk': 'Agza bolmak'},
    'registration_failed': {
      'ru': 'Не удалось зарегистрироваться',
      'tk': 'Hasaba durmak başa barmady'
    },
    'login_failed': {'ru': 'Не удалось войти', 'tk': 'Girmek başa barmady'},
    'no_account': {
      'ru': 'Нет аккаунта? Зарегистрироваться',
      'tk': 'Agzaňyz ýokmy? Agza boluň'
    },
    'login_with': {'ru': 'Войти с помощью', 'tk': 'Başgaça girmek'},
    'login_google': {'ru': 'Войти через Google', 'tk': 'Google bilen gir'},
    'login_yandex': {'ru': 'Войти через Яндекс', 'tk': 'Ýandeks bilen gir'},
    'yandex': {'ru': 'Яндекс', 'tk': 'Ýandeks'},
    'login_apple': {'ru': 'Войти через Apple', 'tk': 'Apple bilen gir'},
    'apple_soon': {
      'ru': 'Вход через Apple скоро будет доступен',
      'tk': 'Apple bilen girmek ýakynda elýeterli bolar'
    },
    'forgot_password': {'ru': 'Забыли пароль?', 'tk': 'Paroly unutdyňyzmy?'},
    'reset_password_hint': {
      'ru':
          'Введите email, указанный при регистрации. Мы отправим ссылку для создания нового пароля.',
      'tk':
          'Hasaba alnanda görkezen email-iňizi giriziň. Täze parol döretmek üçin salgy ibereris.',
    },
    'check_email': {'ru': 'Проверьте почту', 'tk': 'Poçtaňyzy barlaň'},
    'reset_email_sent': {
      'ru':
          'Если аккаунт с таким адресом существует, мы отправили ссылку для сброса пароля на',
      'tk':
          'Şeýle salgyly hasap bar bolsa, paroly täzelemek üçin salgy iberildi:',
    },
    'invalid_email': {
      'ru': 'Введите корректный email',
      'tk': 'Dogry email giriziň'
    },
    'change_password': {'ru': 'Изменить пароль', 'tk': 'Parol çalyşmak'},
    'logout': {'ru': 'Выйти', 'tk': 'Çykyş'},
    'logout_confirm': {
      'ru': 'Вы уверены, что хотите выйти?',
      'tk': 'Çykmak isleýändigiňize ynanýarsyňyzmy?',
    },

    // Профиль
    'edit_profile': {
      'ru': 'Редактировать профиль',
      'tk': 'Şahsy maglumatlary üýtgetmek'
    },
    'no_email_warning': {
      'ru': 'Укажите ваш email в разделе «Редактировать профиль». '
          'Если вы забудете пароль, по нему можно будет легко восстановить доступ к аккаунту. '
          'Без email восстановить аккаунт Owadan Express будет невозможно.',
      'tk': '«Şahsy maglumatlary üýtgetmek» bölüminde email salgyňyzy görkeziň. '
          'Parolyňyzy ýatdan çykaran ýagdaýyňyzda, onuň kömegi bilen hasabyňyzy aňsatlyk bilen dikeldip bilersiňiz. '
          'Email salgysy bolmasa, Owadan Express hasabyňyzy dikeltmek mümkin bolmaz.',
    },
    'order_history': {'ru': 'История заказов', 'tk': 'Sargytlaryň taryhy'},
    'admin_orders': {'ru': 'Заказы', 'tk': 'Sargytlar'},
    'refunds': {'ru': 'Возвраты', 'tk': 'Yzyna gaýtarmalar'},
    'refund_reimbursed': {
      'ru': 'Возврат средств выполнен',
      'tk': 'Yzyna gaýtarma öwezini dolan'
    },
    'all_orders': {'ru': 'Все заказы', 'tk': 'Ähli sargytlar'},
    'stat_today': {'ru': 'Сегодня', 'tk': 'Şu gün'},
    'stat_last_week': {'ru': 'Последние 7 дней', 'tk': 'Soňky 7 gün'},
    'stat_this_month': {'ru': 'Этот месяц', 'tk': 'Bu aý'},
    'stat_this_year': {'ru': 'Этот год', 'tk': 'Bu ýyl'},
    'stat_total': {'ru': 'Всего', 'tk': 'Jemi'},
    'customer': {'ru': 'Клиент', 'tk': 'Müşderi'},
    'last_order': {'ru': 'Последний заказ', 'tk': 'Soňky sargyt'},
    'edit_order_status_title': {
      'ru': 'Изменить статус заказа',
      'tk': 'Sargydyň statusyny üýtgetmek'
    },
    'avans': {'ru': 'Аванс', 'tk': 'Awans'},
    'cancel_order': {'ru': 'Отменить заказ', 'tk': 'Sargydy ýatyrmak'},
    'edit': {'ru': 'Изменить', 'tk': 'Üýtgetmek'},
    'status_updated': {'ru': 'Статус обновлён', 'tk': 'Status täzelendi'},
    'delete_order': {'ru': 'Удалить заказ', 'tk': 'Sargydy pozmak'},
    'delete_order_confirm': {
      'ru': 'Удалить этот заказ? Действие необратимо.',
      'tk': 'Bu sargydy pozmalymy? Bu amaly yzyna gaýtaryp bolmaz.',
    },
    'order_deleted': {'ru': 'Заказ удалён', 'tk': 'Sargyt pozuldy'},
    'my_orders_count': {
      'ru': 'Количество моих заказов',
      'tk': 'Sargytlarymyň sany'
    },
    'messages': {'ru': 'Сообщения', 'tk': 'Hatyňyz'},
    'return_item': {'ru': 'Вернуть товар', 'tk': 'Harydy yzyna tabşyrmak'},
    'contact_us': {'ru': 'Связаться с нами', 'tk': 'Habarlaşmak'},
    'about_us': {'ru': 'О нас', 'tk': 'Biz barada'},
    'about_hero_subtitle': {
      'ru': 'Узнайте больше об Owadan Express',
      'tk': 'Owadan Express barada has giňişleýin öwreniň',
    },
    'about_contact_prompt': {
      'ru': 'Остались вопросы? Напишите нам.',
      'tk': 'Soragyňyz barmy? Bize ýazyň.',
    },
    'about_empty': {
      'ru': 'Информация о нас пока недоступна.',
      'tk': 'Biz baradaky maglumat häzir elýeterli däl.',
    },
    'about_load_failed': {
      'ru': 'Не удалось загрузить информацию. Попробуйте ещё раз.',
      'tk': 'Maglumat ýüklenmedi. Täzeden synanyşyň.',
    },
    'retry': {'ru': 'Повторить', 'tk': 'Gaýtadan synanyş'},
    'how_to_order': {'ru': 'Как сделать заказ', 'tk': 'Nädip sargyt etmeli'},
    'language': {'ru': 'Язык', 'tk': 'Dil'},
    'dark_mode': {'ru': 'Ночной режим', 'tk': 'Gijeki tertip'},
    'checkout_summary': {'ru': 'Ваш заказ', 'tk': 'Sargydyňyz'},
    'default_badge': {'ru': 'Основной', 'tk': 'Esasy'},
    'added_to_cart': {'ru': 'Добавлено в корзину', 'tk': 'Sebede goşuldy'},
    'chat_today': {'ru': 'Сегодня', 'tk': 'Şu gün'},
    'chat_yesterday': {'ru': 'Вчера', 'tk': 'Düýn'},
    'profile_personal': {'ru': 'Личные данные', 'tk': 'Şahsy maglumatlar'},
    'profile_contacts': {'ru': 'Контакты', 'tk': 'Aragatnaşyk'},
    'read_more': {'ru': 'Читать далее', 'tk': 'Dowamyny oka'},
    'read_less': {'ru': 'Свернуть', 'tk': 'Gizlemek'},
    'copy': {'ru': 'Копировать', 'tk': 'Göçürmek'},
    'copied': {'ru': 'Скопировано', 'tk': 'Göçürildi'},
    'article': {'ru': 'Артикул', 'tk': 'Artikul'},
    'drawer_section_catalog': {'ru': 'Каталог', 'tk': 'Katalog'},
    'view_as_grid': {'ru': 'Плиткой', 'tk': 'Tor görnüşinde'},
    'view_as_list': {'ru': 'Списком', 'tk': 'Sanaw görnüşinde'},
    'guest_title': {'ru': 'Гость', 'tk': 'Myhman'},
    'orders_total': {'ru': 'Всего', 'tk': 'Jemi'},
    'section_account': {'ru': 'Аккаунт', 'tk': 'Hasap'},
    'section_admin': {'ru': 'Управление', 'tk': 'Dolandyryş'},
    'section_help': {'ru': 'Помощь', 'tk': 'Kömek'},
    'section_preferences': {'ru': 'Настройки', 'tk': 'Sazlamalar'},

    // Заказы / отслеживание
    'track_order': {'ru': 'Отследить заказ', 'tk': 'Sargydy yzarlamak'},
    'status_pending': {'ru': 'В ожидании', 'tk': 'Garaşylýar'},
    'status_being_delivered': {'ru': 'Заказ в пути', 'tk': 'Sargydyňyz ýolda'},
    'status_received': {'ru': 'Доставлено', 'tk': 'Gowşuryldy'},
    'status_cancelled': {'ru': 'Заказ отменён', 'tk': 'Sargyt ýatyryldy'},
    'request_refund': {
      'ru': 'Запросить возврат',
      'tk': 'Yzyna gaýtarmak soralýar'
    },
    'refund_arranged': {
      'ru': 'Возврат оформлен',
      'tk': 'Yzyna gaýtarmak resmileşdirildi'
    },
    'coupon_applied': {'ru': 'Купон применён', 'tk': 'Kupon ulanyldy'},
    'coupon_error': {
      'ru': 'Не удалось применить купон',
      'tk': 'Kupony ulanmak başa barmady'
    },
    'no_products_yet': {'ru': 'Товаров пока нет', 'tk': 'Häzirlikçe haryt ýok'},
    'network_error': {
      'ru': 'Ошибка сети. Проверьте подключение к интернету.',
      'tk': 'Tor ýalňyşlygy. Internet birikmäňizi barlaň.',
    },
    'google_no_token': {
      'ru': 'Google не вернул токен. Попробуйте ещё раз.',
      'tk': 'Google token bermedi. Täzeden synanyşyň.',
    },
    'google_no_connection': {
      'ru': 'Нет соединения с Google. Проверьте интернет.',
      'tk': 'Google bilen birikme ýok. Interneti barlaň.',
    },
    'google_not_configured': {
      'ru': 'Вход через Google не настроен для этой версии приложения.',
      'tk': 'Bu programma wersiýasy üçin Google arkaly giriş sazlanmadyk.',
    },
    'google_unavailable': {
      'ru': 'Google временно не может выполнить вход. Попробуйте позже.',
      'tk': 'Google arkaly giriş wagtlaýyn elýeterli däl. Soňrak synanyşyň.',
    },
    'google_sign_in_failed': {
      'ru': 'Не удалось войти через Google.',
      'tk': 'Google arkaly girmek başa barmady.',
    },
    'auth_open_failed': {
      'ru': 'Не удалось открыть вход через {provider}.',
      'tk': '{provider} arkaly giriş sahypasyny açyp bolmady.',
    },
    'auth_no_email': {
      'ru': '{provider} не передал email. Попробуйте другой способ входа.',
      'tk': '{provider} email bermedi. Başga giriş usulyny synanyşyň.',
    },
    'auth_provider_failed': {
      'ru': 'Не удалось войти через {provider}. Попробуйте ещё раз.',
      'tk': '{provider} arkaly girmek başa barmady. Täzeden synanyşyň.',
    },
    'auth_error_code': {'ru': 'код', 'tk': 'kod'},
    'offline_title': {'ru': 'Нет подключения', 'tk': 'Internet birikmesi ýok'},
    'offline_body': {
      'ru': 'Проверьте Wi-Fi или мобильный интернет и попробуйте снова.',
      'tk': 'Wi-Fi ýa-da mobil interneti barlap, täzeden synanyşyň.',
    },
    'service_unavailable_title': {
      'ru': 'Не удаётся подключиться',
      'tk': 'Serwere birigip bolmaýar',
    },
    'service_unavailable_body': {
      'ru': 'Сервис временно недоступен. Попробуйте ещё раз через минуту.',
      'tk': 'Hyzmat wagtlaýyn elýeterli däl. Bir minutdan gaýtadan synanyşyň.',
    },
    'retry_connection': {
      'ru': 'Проверить соединение',
      'tk': 'Birikmäni barlamak',
    },
    'checking_connection': {
      'ru': 'Проверяем соединение...',
      'tk': 'Birikme barlanýar...',
    },
    'reconnect_hint': {
      'ru': 'Когда интернет появится, приложение подключится автоматически.',
      'tk': 'Internet gaýdyp gelende programma awtomatik biriger.',
    },
  };

  /// Возвращает перевод по ключу для языка [lang] ('ru', 'tk' или 'en').
  static String t(String key, String lang) {
    if (lang == 'en') return appStringsEn[key] ?? key;
    final entry = _dict[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['ru'] ?? key;
  }

  static String days(int count, String lang) {
    if (lang == 'tk') return 'gün';
    if (lang == 'en') return count == 1 ? 'day' : 'days';
    final lastTwo = count % 100;
    if (lastTwo >= 11 && lastTwo <= 14) return 'дней';
    return switch (count % 10) {
      1 => 'день',
      2 || 3 || 4 => 'дня',
      _ => 'дней',
    };
  }
}
