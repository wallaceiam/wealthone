import * as React from 'react';
import StyleContext from './StyleContext';
import type { Style } from './Style';

interface StyleProps {
  readonly value: Style;
};

const StyleProvider = ({ value, children }: React.PropsWithChildren<StyleProps>) => {
  return (
    <StyleContext.Provider value={value}>
      {children}
    </StyleContext.Provider>
  );
};

export default StyleProvider;
