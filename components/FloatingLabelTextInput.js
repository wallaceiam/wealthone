import React, { Component } from 'react';
import {
    View,
    TextInput,
    Text,
} from 'react-native';

import { globalStyles } from './../Style';
import { globalColours } from '../Colours';

export class FloatingLabelTextInput extends Component {
    state = {
        isFocused: false,
    };

    handleFocus = () => this.setState({ isFocused: true });
    handleBlur = () => this.setState({ isFocused: false });

    render() {
        const { label, value, ...props } = this.props;
        const { isFocused } = this.state;
        const labelStyle = {
            position: 'absolute',
            left: 0,
            top: !isFocused && (value || '') === ''  ? 26 : 0,
            color: !isFocused ? globalColours.quinary: globalColours.primary,
        };
        return (
            <View style={{ paddingTop: 18 }}>
                <Text style={labelStyle}>
                    {label}
                </Text>
                <TextInput
                    {...props}
                    value={value}
                    style={[globalStyles.textInput, isFocused && globalStyles.textInputFocused]}
                    onFocus={this.handleFocus}
                    onBlur={this.handleBlur}
                    blurOnSubmit
                />
            </View>
        );
    }
}

