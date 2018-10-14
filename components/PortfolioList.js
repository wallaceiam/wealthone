
import React, { Component } from 'react';
import { StyleSheet, View, SectionList, Text, Platform, TouchableOpacity } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import { withNavigation } from 'react-navigation';
import { connect } from 'react-redux';

import { globalStyles } from './../Style';
import { AccountTypes } from '../models/Account';

class PortfolioList extends React.Component {

    constructor(props) {
        super(props);
    }

    onPortfolioSelected = (item) => {
        this._navToAccount(item.id);
    }

    _navToAccount = (accountId) => {
        this.props.navigation.navigate('Account', { accountId: accountId });
      }

    renderItem = ({ item }) => {
        return (
            <TouchableOpacity onPress={this.onPortfolioSelected.bind(this, item)}>
                <View style={{
                    flex: 1,
                    flexDirection: 'row',
                    justifyContent: 'space-between',
                    marginLeft: 32,
                    marginRight: 32
                }}>
                    <View style={{
                        flex: 1,
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                        marginTop: 16,
                        marginBottom: 16
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
                            style={globalStyles.h2} />
                    </View>
                </View>
            </TouchableOpacity>
        );
    }

    render() {
        const accounts = (this.props.portfolio.accounts || []);
        const records = (this.props.portfolio.records || []);
        const last = records.length - 1;

        const assets = accounts.filter(x => x.accountType === AccountTypes.Asset).map(x => {
            return {
                id: x.id,
                name: x.name,
                provider: x.provider,
                amount: last < 0 ? 0 : (records[last].totals.find(y => y.id === x.id).amount || 0)
            }
        });
        const liabilities = accounts.filter(x => x.accountType === AccountTypes.Liability).map(x => {
            return {
                id: x.id,
                name: x.name,
                provider: x.provider,
                amount: last < 0 ? 0 : (records[last].totals.find(y => y.id === x.id).amount || 0)
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
