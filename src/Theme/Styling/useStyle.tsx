import * as React from 'react';
import StyleContext from './StyleContext';

const useStyle = () => {
  const style = React.useContext(StyleContext);

  return style;
};

export default useStyle;
