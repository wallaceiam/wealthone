import * as React from 'react';
import type {Style} from './Style';
import {DefaultStyle} from './Styles';

const StyleContext = React.createContext<Style>(DefaultStyle);

export default StyleContext;
