import React, { useState } from 'react';
import { Animated, Text, TouchableOpacity, View } from 'react-native';
import DatePickerIOS from '@react-native-community/datetimepicker';

import { useStyle, useTheme } from '../Theme';
import { toUtc } from '../Redux/DateHelpers';

interface IDateInputProps {
  label: string;
  date: Date;
  onDateChanged: (date: Date) => void;
}

const DateInput = ({ label, date, onDateChanged }: IDateInputProps) => {
  const style = useStyle();
  const theme = useTheme();

  const [isDateExpanded, setDateExpanded] = useState(false);
  const [animation] = useState(new Animated.Value(32));

  const onToggleDate = () => {
    const MIN_HEIGHT = 32;
    const MAX_HEIGHT = 216;
    //Step 1
    let initialValue = isDateExpanded ? MAX_HEIGHT + MIN_HEIGHT : MIN_HEIGHT,
      finalValue = isDateExpanded ? MIN_HEIGHT : MAX_HEIGHT + MIN_HEIGHT;

    setDateExpanded(!isDateExpanded); //Step 2

    animation.setValue(initialValue); //Step 3
    Animated.spring(
      //Step 4
      animation,
      {
        toValue: finalValue,
        useNativeDriver: false,
      },
    ).start(); //Step 5
  };

  return (
    <Animated.View
      style={[
        style.bottomMargin,
        style.topMargin,
        style.column,
        { marginTop: 32, minHeight: animation },
      ]}>
      <View style={{ height: 32 }}>
        <View style={[style.row, style.noMargins]}>
          <View style={[style.column, style.noMargins]}>
            <Text style={style.label}>{label}</Text>
          </View>
          <View
            style={{
              flex: 1,
              borderBottomWidth: 1,
              borderBottomColor: '#E7E7E7',
            }}>
            <TouchableOpacity onPress={onToggleDate}>
              <Text style={[style.textInput, { textAlign: 'right' }]}>
                {date.toDateString()}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
      <View>
        {isDateExpanded && (
          <DatePickerIOS
            textColor={theme.colors.primary}
            mode="date"
            display="spinner"
            maximumDate={new Date()}
            value={date}
            onChange={(_event, newDate) =>
              newDate !== undefined && onDateChanged(toUtc(newDate))
            }
          />
        )}
      </View>
    </Animated.View>
  );
};

export default DateInput;
