import React, {useState} from 'react';
import {View, TextInput, Text} from 'react-native';

import {useStyle, useTheme} from '../Theme';

interface IFloatingLabelTextLabelProps {
  label?: string;
  value?: string;
  onChangeText?: (text: string) => void;
}

const FloatingLabelTextLabel = ({
  label,
  value,
  onChangeText,
}: IFloatingLabelTextLabelProps) => {
  const [isFocused, setIsFocused] = useState(false);
  const theme = useTheme();
  const style = useStyle();

  const labelStyle = {
    left: 0,
    top: !isFocused && (value || '') === '' ? 16 : -16,
    color: !isFocused ? theme.colors.primary_alpha : theme.colors.primary,
  };
  const inputStyle = {
    borderBottomColor: !isFocused
      ? theme.colors.primary_alpha
      : theme.colors.primary,
  };
  return (
    <View style={style.topMargin}>
      <Text style={[style.label, labelStyle, {position: 'absolute'}]}>
        {label}
      </Text>
      <TextInput
        value={value}
        style={[style.textInput, inputStyle]}
        onFocus={() => setIsFocused(true)}
        onBlur={() => setIsFocused(false)}
        onChangeText={onChangeText}
        blurOnSubmit
      />
    </View>
  );
};

export default FloatingLabelTextLabel;
