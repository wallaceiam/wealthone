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
        const { stats, accounts } = this.props.portfolio;
        const accountId = this.props.accountId;
        const { byAccount } = (stats || { byAccount: [] });
        const account = (byAccount || []).length > 0 ? byAccount.find(x => x.id === accountId) : undefined;
        const latest = (account !== undefined && account !== null) ? 
            account.records[account.records.length - 1].total : 0;
        const nAccount = accounts.find(x => x.id === accountId);
        const accountName = (nAccount !== undefined && nAccount !== null) ? `${nAccount.name} - ${nAccount.provider}`: '';

        return (
            <View style={styles.container}>
                <Text>{ accountName }</Text>
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