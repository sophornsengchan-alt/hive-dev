public with sharing class LocaleFormatter {
	
	/**
	 * currency iso code map.
	 */
	private static Map<String,String> currencyMap = new Map<String,String> {
		'de_DE'=>'EUR',
		'en_US'=>'USD',
		'en_AU'=>'AUD',
		'en_GB'=>'GBP'
	};
	
	/**
	 * currency symbol map.
	 */
	private static Map<String,String> currencySymbolMap = new Map<String,String> {
		'de_DE'=>'€',
		'en_US'=>'$',
		'en_AU'=>'$',
		'en_GB'=>'£'
	};
	
	/**
	 *
	 * @param val decimal
	 * @param oppLocale opportunity field for the locale format
	 * @return the formated string of the decimal
	 */
	public static String getLocaleFormat(Decimal val, String oppLocale) {
		if (val == null) {
			val = 0;
		}
		
		String qLocale = getQuoteLocale(oppLocale);
		String result = doFormatting(val, qLocale);
		
		// Update: No currency!
		//result = result+' '+getCurrencySymbol(qLocale);
		
		return result;
	}
	
	/**
	 *
	 * @param qLocale selected locale format
	 * @return the currency symbol of the locale format
	 */
	private static String getCurrencySymbol(String qLocale) {
		if (currencySymbolMap.containsKey(qLocale)) {
			return currencySymbolMap.get(qLocale);
		} else {
			return '€'; // default
		}
	}
	
	/**
	 *
	 * @param oppLocale opportunity field for the locale format
	 * @return the currency iso code of the locale format
	 */
	public static String getCurrency(String oppLocale) {
		String qLocale = getQuoteLocale(oppLocale);
		
		if (currencyMap.containsKey(qLocale)) {
			return currencyMap.get(qLocale);
		} else {
			return 'EUR'; // default
		}
	}
	
	/**
	 *
	 * @param oppLocale opportunity field for the locale format
	 * @return selected locale format
	 */
	private static String getQuoteLocale(String oppLocale) {
		String qLocale;
		
		if (oppLocale != null) {
			qLocale = oppLocale;
		} else {
			qLocale = UserInfo.getLocale();
		}
		
		return qLocale;
	}
	
	/**
	 *
	 * @param val decimal
	 * @param qLocale selected locale format
	 * @return the formated string of the decimal
	 */
	private static String doFormatting(Decimal val, String qLocale) {
		String qCurrency = currencyMap.get(qLocale);
		String result;
		
		if (qLocale == 'de_DE') {
			 result = doFormatting(val, ',', '.'); // doFormatting(val, '.', ',');
		} else {
			result = doFormatting(val, '.', ',');   // doFormatting(val, ',', '.');
		}
		
		return result;
	}
	
	/**
	 *
	 * @param val decimal
	 * @param osep in germany: "."
	 * @param nsep in germany: ","
	 * @return the formated string of the decimal
	 */
	private static String doFormatting(Decimal val, String osep, String nsep) {
		Boolean isNegative = false;
		Integer i = 6;
		String s;
		String tmp;
		
		s = val.setScale(2).toPlainString().trim();
		
		if (s.startsWith('-')) {
			s = s.substring(1, s.length());
			isNegative = true;
		}
		
		s = s.replace(osep, nsep);
		
		while (s.length() > i) {
			tmp = s.substring(0, s.length() - i) + osep + s.substring(s.length() - i);
			s = tmp;
			i += 4;
		}
		
		if (isNegative) {
			s = '-'+s;
		}
		
		return s;
	}
	

}