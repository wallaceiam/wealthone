import { Theme } from '@react-navigation/native';

export interface ITheme extends Theme {
  colors: {
    primary: string;
    secondary: string;
    tertiary: string;
    quaternary: string;
    quinary: string;
    senary: string;

    alt: string;
    white: string;

    inactive: string;

    primary_o20: string;
    primary_alpha: string;

    background: string;
    card: string;
    text: string;
    border: string;
    notification: string;

    danger: string;
  };
}
