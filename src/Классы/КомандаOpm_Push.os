#Использовать asserts
#Использовать logos
#Использовать gitrunner

Перем ДопустимыеИменаКаналов;
Перем Лог;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Отправить пакет в хаб пакетов");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--token", "  Токен авторизации на GitHub.com
	|             Токен авторизации создается на странице https://github.com/settings/tokens
	|             Токен используется только для проверки авторизации на GitHub.com и прав на репозиторий, выдача дополнительных разрешений в ""scopes"" НЕ требуется.");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--file", "   Маска или имя файла пакета.");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "--channel", "Канал публикации. Возможные значения: stable, dev.
	|             В случае отправки из ветки master гит-репозитория данный параметр можно опустить - будет использоваться канал ""stable"".
	|             В любых других случаях его заполнение обязательно.");
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

// Выполняет логику команды
// 
// Параметры:
//   ПараметрыКоманды - Соответствие ключей командной строки и их значений
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
	
	ТокенАвторизации = ПолучитьЗначениеОбязательногоПараметра(ПараметрыКоманды, "--token");
	
	МаскаФайлаПакета = ПолучитьЗначениеОбязательногоПараметра(ПараметрыКоманды, "--file");
	ФайлПакета = ПолучитьФайлПакета(МаскаФайлаПакета);
	
	Канал = ПолучитьИмяКаналаПубликации(ПараметрыКоманды);
	
	ОтправитьПакетВХаб(ТокенАвторизации, ФайлПакета, Канал);
	Возврат 0;
	
КонецФункции

Функция ПолучитьЗначениеОбязательногоПараметра(Знач ЗначенияПараметров, Знач ИмяПараметра)
	ЗначениеПараметра = ЗначенияПараметров[ИмяПараметра];
	Ожидаем.Что(ЗначениеПараметра, СтрШаблон("Не заполнено значение обязательного параметра %1", ИмяПараметра)).Заполнено();
	
	Возврат ЗначениеПараметра;
КонецФункции

Функция ПолучитьИмяКаналаПубликации(Знач ЗначенияПараметров)
	
	ГитРепозиторий = Новый ГитРепозиторий();
	ГитРепозиторий.УстановитьРабочийКаталог(ТекущийКаталог());
	
	КаналПубликации = СокрЛП(ЗначенияПараметров["--channel"]);
	
	Если ЗначениеЗаполнено(КаналПубликации) Тогда
		Если ЭтоДопустимыйКаналПубликации(КаналПубликации) Тогда
			Возврат КаналПубликации;
		Иначе
			ТекстСообщения = "Указано недопустимое имя канала. Допустимые имена:" + Символы.ПС;
			Для Каждого КлючИЗначение Из ДопустимыеИменаКаналов Цикл
				ТекстСообщения = ТекстСообщения + КлючИЗначение.Значение + Символы.ПС;
			КонецЦикла;
			
			ВызватьИсключение ТекстСообщения;
		КонецЕсли;
	КонецЕсли;
	
	Если НЕ ГитРепозиторий.ЭтоРепозиторий() Тогда
		ВызватьИсключение "Не заполнено значение обязательного параметра --channel";
	КонецЕсли;
	
	ИмяВетки = ГитРепозиторий.ПолучитьТекущуюВетку();
	Если ИмяВетки <> "master" Тогда
		ВызватьИсключение "Не заполнено значение обязательного параметра --channel";
	КонецЕсли;
	
	Возврат ДопустимыеИменаКаналов.Стабильный;
	
КонецФункции

Функция ЭтоДопустимыйКаналПубликации(КаналПубликации)
	Результат = Ложь;
	Для Каждого КлючИЗначение Из ДопустимыеИменаКаналов Цикл
		Если КлючИЗначение.Значение = КаналПубликации Тогда
			Результат = Истина;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	
	Возврат Результат;
КонецФункции

Функция ПолучитьФайлПакета(МаскаФайлаПакета)
	
	НайденныеФайлы = НайтиФайлы(ТекущийКаталог(), МаскаФайлаПакета);
	
	Если НайденныеФайлы.Количество() = 0 Тогда
		ВызватьИсключение "По переданной маске файла пакета не найдено файлов";
	КонецЕсли;
	Если НайденныеФайлы.Количество() > 1 Тогда
		ВызватьИсключение "По переданной маске файла пакета найдено больше одного файла";
	КонецЕсли;
	
	Возврат НайденныеФайлы[0];
	
КонецФункции

Процедура ОтправитьПакетВХаб(Знач ТокенАвторизации, Знач ФайлПакета, Знач Канал)
	
	ДвоичныеДанныеФайла = Новый ДвоичныеДанные(ФайлПакета.ПолноеИмя);
	ДвоичныеДанныеФайлаВBase64 = Base64Строка(ДвоичныеДанныеФайла);
	
	Сервер = КонстантыOpm.СерверУдаленногоХранилища;
	Ресурс = КонстантыOpm.РесурсПубликацииПакетов;
	
	Заголовки = Новый Соответствие();
	Заголовки.Вставить("OAUTH-TOKEN", ТокенАвторизации);
	Заголовки.Вставить("FILE-NAME", ФайлПакета.Имя);
	Заголовки.Вставить("CHANNEL", Канал);
	
	Соединение = Новый HTTPСоединение(Сервер);
	Запрос = Новый HTTPЗапрос(Ресурс, Заголовки);
	Запрос.УстановитьТелоИзДвоичныхДанных(ДвоичныеДанныеФайла);
	
	Ответ = Соединение.ОтправитьДляОбработки(Запрос);
	ТелоОтвета = Ответ.ПолучитьТелоКакСтроку();
	
	Если Ответ.КодСостояния <> 200 Тогда
		ВызватьИсключение ТелоОтвета;
	КонецЕсли;
	
	Лог.Информация(ТелоОтвета);
	
КонецПроцедуры

Лог = Логирование.ПолучитьЛог("oscript.app.opm");

ДопустимыеИменаКаналов = Новый Структура;
ДопустимыеИменаКаналов.Вставить("Стабильный", "stable");
ДопустимыеИменаКаналов.Вставить("Разработческий", "dev");
