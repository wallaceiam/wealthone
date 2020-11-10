import * as React from 'react';
import StyleContext from './StyleContext';
import type { Style } from './Style';

type Props = {
  value: Style;
  children: React.ReactNode;
};

const StyleProvider = ({ value, children }: Props)  => {
  return (
    <StyleContext.Provider value={value}>{children}</StyleContext.Provider>
  );
};

export default StyleProvider;
