import React from 'react';
import { Text, Animated, View, StyleSheet, Platform } from 'react-native';
import { connect } from 'react-redux';
import { FormattedCurrency } from 'react-native-globalize';

import { globalStyles } from './../Style';

class HomeTopBar extends React.Component {

    constructor(props) {
        super(props);
    }

    render() {
        const { stats } = this.props.portfolio;
        const { netWorth } = (stats || { netWorth: [] });
        const interm = (netWorth || []).length > 0 ? netWorth[netWorth.length - 1].total : 0;
        const latest = interm || 0;

        return (
            <View style={styles.container}>
                <Text>Your total net worth</Text>
                <FormattedCurrency
                    value={latest}
                    currency="GBP"
                    maximumFractionDigits={0}
                    minimumFractionDigits={0}
                    style={globalStyles.h1} />
            </View>
        );
    }
}

const styles = StyleSheet.create({
    container: {
        backgroundColor: '#fff',
        padding: 32,
        paddingTop: 16,
        paddingBottom: 0
    },
});

const mapStateToProps = (state) => {
    const { portfolio } = state
    return { portfolio }
};

export default connect(mapStateToProps)(HomeTopBar);