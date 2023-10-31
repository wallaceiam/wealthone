import {DarkTheme as _DarkTheme} from '@react-navigation/native';
import {ITheme} from './ITheme';

const DarkTheme: ITheme = {
  dark: true,
  colors: {
    senary: '#1E2833',
    quinary: '#2A4054',
    quaternary: '#5E7A92',
    tertiary: '#A1B3C4',
    secondary: '#CBD5E0',
    primary: '#E5E7EE',

    alt: '#5E7A92',
    white: 'rgba(30, 40, 51, 0.5)',

    inactive: '#2A4054',
    primary_o20: 'rgba(47,185,174,0.2)',

    primary_alpha: 'rgba(229, 231, 238, 0.5)',
    background: '#010101',
    text: '#E5E7EE',
    danger: 'red',

    notification: _DarkTheme.colors.notification,
    card: _DarkTheme.colors.card,
    border: _DarkTheme.colors.border,
  },
};

export default DarkTheme;
