import {useTheme as _useTheme} from '@react-navigation/native';
import {ITheme} from './ITheme';

const useTheme = (): ITheme => _useTheme() as ITheme;

export default useTheme;
