import React from 'react';
import { TouchableOpacity, View, Text } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { useStyle, useTheme } from '../../../Theme';

const MenuItem = ({ text, icon, onClick }) => {
  const style = useStyle();
  const theme = useTheme();

  return (
    <TouchableOpacity onPress={onClick}>
      <View style={style.row}>
        <Text style={[style.text, style.bottomMargin]}>{text}</Text>
        {icon !== undefined ? (
          <FeatherIcon name={icon} size={20} color={theme.colors.primary} />
        ) : null}
      </View>
    </TouchableOpacity>
  );
};

export default MenuItem;
