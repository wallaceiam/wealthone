import {DefaultTheme as _LightTheme} from '@react-navigation/native';
import {ITheme} from './ITheme';

const DefaultTheme: ITheme = {
  dark: false,
  colors: {
    primary: '#1E2833',
    secondary: '#2A4054',
    tertiary: '#5E7A92',
    quaternary: '#A1B3C4',
    quinary: '#CBD5E0',
    senary: '#E5E7EE',

    alt: '#5E7A92',
    white: '#FFFFFF',

    inactive: '#2A4054',
    primary_o20: 'rgba(47,185,174,0.2)',

    primary_alpha: 'rgba(30, 40, 51, 0.5)',
    background: '#fff',
    text: '#1E2833',
    danger: 'red',

    notification: _LightTheme.colors.notification,
    card: _LightTheme.colors.card,
    border: _LightTheme.colors.border,
  },
};

export default DefaultTheme;
