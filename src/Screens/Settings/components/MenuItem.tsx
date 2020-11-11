import React from 'react';
import { TouchableOpacity, View, Text } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { useStyle, useTheme } from '../../../Theme';

interface IMenuItemProps {
  text: string;
  subText?: string;
  icon: string;
  onClick: () => void;
}

const MenuItem = ({ text, subText, icon, onClick }: IMenuItemProps) => {
  const style = useStyle();
  const theme = useTheme();

  return (
    <TouchableOpacity onPress={onClick}>
      <View style={style.row}>
        <View style={[style.column, style.noMargins, style.bottomMargin]}>
          <Text style={style.text}>{text}</Text>
          {subText !== undefined && (
            <Text style={style.subText}>{subText}</Text>
          )}
        </View>
        {icon !== undefined ? (
          <FeatherIcon name={icon} size={20} color={theme.colors.primary} />
        ) : null}
      </View>
    </TouchableOpacity>
  );
};

export default MenuItem;
