public with sharing class WeatherService {
    public class WeatherServiceException extends Exception {}

    private static final String API_URL = 'https://api.openweathermap.org/data/2.5/weather';

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getWeatherByCity(String cityName) {
        String apiKey = getApiKey();
        String requestUrl = API_URL + '?q=' + EncodingUtil.urlEncode(cityName, 'UTF-8') + '&appid=' + apiKey;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(requestUrl);
        request.setMethod('GET');
        
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } else {
                throw new WeatherServiceException('Unable to retrieve weather data. HTTP Status: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new WeatherServiceException('Exception during API call: ' + e.getMessage());
        }
    }
    
    private static String getApiKey() {
        ExternalAPIKeys__c settings = ExternalAPIKeys__c.getOrgDefaults();
        if (settings == null || String.isEmpty(settings.ApiKey__c)) {
            throw new WeatherServiceException('API Key not found in Custom Settings.');
        }
        return settings.ApiKey__c;
    }
}
