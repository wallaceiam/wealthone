import React, {useState} from 'react';
import {View, TextInput, Text} from 'react-native';

import {useStyle, useTheme} from '../Theme';

interface INumericProps {
  label?: string;
  value?: string;
  placeholder?: string;
  onChangeText?: (text: string) => void;
}

const NumericInput = ({
  label,
  value,
  placeholder,
  onChangeText,
}: INumericProps) => {
  const [isFocused, setFocused] = useState(false);
  const theme = useTheme();
  const style = useStyle();

  const labelStyle = {
    left: 0,
    top: !isFocused && (value || '') === '' ? 26 : 0,
    color: !isFocused ? theme.colors.primary_alpha : theme.colors.primary,
  };
  const inputStyle = {
    borderBottomColor: !isFocused
      ? theme.colors.primary_alpha
      : theme.colors.primary,
  };
  return (
    <View style={style.marginTop}>
      <Text style={[style.label, labelStyle, {position: 'absolute'}]}>
        {label}
      </Text>
      <TextInput
        value={value}
        keyboardType="number-pad"
        style={[style.textInput, style.numberInput, inputStyle]}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        blurOnSubmit
        placeholder={placeholder}
        onChangeText={onChangeText}
      />
    </View>
  );
};

export default NumericInput;
