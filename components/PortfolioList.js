
import React, { Component } from 'react';
import { StyleSheet, View, SectionList, Text, Platform, TouchableOpacity } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { withNavigation } from 'react-navigation';
import { connect } from 'react-redux';

import { globalStyles } from './../Style';
import { globalColours } from './../Colours';
import { IsAsset } from '../models/Account';

class PortfolioList extends React.Component {

    constructor(props) {
        super(props);
    }

    onPortfolioSelected = (item) => {
        this._navToAccount(item.id);
    }

    _navToAccount = (accountId) => {
        this.props.navigation.navigate('HomeAccount', { accountId: accountId });
    }

    renderItem = ({ item }) =>
        (
            <TouchableOpacity onPress={this.onPortfolioSelected.bind(this, item)}>
                <View style={globalStyles.row}>
                    <View style={{
                        flex: 1,
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                        marginTop: 'auto',
                        marginBottom: 'auto'
                    }}>
                        <Text>{item.name} </Text>
                        <Text>{item.provider} </Text>
                    </View>
                    <View>
                        <FormattedCurrency
                            value={item.amount}
                            currency="GBP"
                            maximumFractionDigits={0}
                            minimumFractionDigits={0}
                            style={[globalStyles.h2]} />
                    </View>
                    <View style={{
                        marginTop: 'auto',
                        marginBottom: 'auto'
                    }}>
                        <FeatherIcon name="chevron-right" color={globalColours.primary} />
                    </View>
                </View>
            </TouchableOpacity>
        );

    render() {
        const accounts = (this.props.portfolio.accounts || []);
        const records = (this.props.portfolio.records || []);
        const last = records.length - 1;

        const assets = accounts.filter(x => x.isAsset === IsAsset.Asset).map(x => {
            const lastRecord = last >= 0 ? records[last].totals.find(y => y.id === x.id) : undefined;
            return {
                id: x.id,
                name: x.name,
                provider: x.provider,
                amount: last < 0 ? 0 : (lastRecord !== undefined && lastRecord !== null ? lastRecord.amount : 0)
            }
        });
        const liabilities = accounts.filter(x => x.isAsset === IsAsset.Liability).map(x => {
            const lastRecord = last >= 0 ? records[last].totals.find(y => y.id === x.id) : undefined;
            return {
                id: x.id,
                name: x.name,
                provider: x.provider,
                amount: last < 0 ? 0 : (lastRecord !== undefined && lastRecord !== null ? lastRecord.amount : 0)
            }
        });

        const sections = assets.length > 0 && liabilities.length > 0 ?
            [{ title: 'Assets', data: assets },
            { title: 'Liabilities', data: liabilities },
            ] : (
                assets.length > 0 ? [{ title: 'Assets', data: assets }] :
                    (liabilities.length > 0 ? [{ title: 'Liabilities', data: liabilities }] : [])
            );

        return (
            <View style={{ marginTop: (Platform.OS) == 'ios' ? 20 : 0 }}>

                <SectionList
                    sections={sections}

                    renderSectionHeader={({ section }) => <Text style={globalStyles.sectionHeaderStyle}> {section.title} </Text>}
                    renderItem={this.renderItem}
                    keyExtractor={(item, index) => index}

                />
            </View>);
    }
}

const styles = StyleSheet.create({



    sectionListItemStyle: {
        padding: 24,
    },

    elementsContainer: {
        flex: 1,
        flexDirection: 'column',
        justifyContent: 'space-between',
    }

});

const mapStateToProps = (state) => {
    const { portfolio } = state
    return { portfolio }
};

export default connect(mapStateToProps)(withNavigation(PortfolioList));
