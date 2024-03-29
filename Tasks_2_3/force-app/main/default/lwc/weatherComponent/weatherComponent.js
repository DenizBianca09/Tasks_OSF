import { LightningElement, track } from 'lwc';
import getWeatherByCity from '@salesforce/apex/WeatherService.getWeatherByCity';

export default class WeatherComponent extends LightningElement {
    @track cityName = ''; // Numele orașului introdus de utilizator
    @track displayedCityName = ''; // Numele orașului afișat
    @track rawWeatherData; // Date brute de la API
    @track error;

    // Getter pentru temperatura
    get temperature() {
        return this.rawWeatherData ? `${this.rawWeatherData.main.temp}°K` : '';
    }

    // Getter pentru descrierea vremii
    get weatherDescription() {
        return this.rawWeatherData && this.rawWeatherData.weather.length > 0
            ? this.rawWeatherData.weather[0].description
            : '';
    }

    // Getter pentru URL-ul iconiței
    get iconUrl() {
        return this.rawWeatherData && this.rawWeatherData.weather.length > 0
            ? `https://openweathermap.org/img/w/${this.rawWeatherData.weather[0].icon}.png`
            : '';
    }

    handleCityNameChange(event) {
        this.cityName = event.target.value;
    }

    getWeather() {
        getWeatherByCity({ cityName: this.cityName })
            .then(result => {
                this.rawWeatherData = result;
                this.displayedCityName = this.cityName; // Actualizează numele orașului afișat
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.rawWeatherData = undefined;
                this.displayedCityName = ''; // Resetare nume oraș la eroare
            });
    }
}
