import * as React from 'react';
import DefaulStyle from './DefaultStyle';
import type { Style } from './Style';

const StyleContext = React.createContext<Style>(DefaulStyle);

export default StyleContext;
