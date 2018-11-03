
import React, { Component } from 'react';
import { StyleSheet, View, SectionList, Text, Platform, TouchableOpacity } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import { withNavigation } from 'react-navigation';
import { connect } from 'react-redux';

import { globalStyles } from './../Style';
import { IsAsset } from '../models/Account';

export default class AccountStats extends React.Component {

    constructor(props) {
        super(props);
    }

    renderItem = ({ item }) => {

        return item.type === 'currency' ? (
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
                </View>
                <View>
                    <FormattedCurrency
                        value={item.value}
                        currency="GBP"
                        maximumFractionDigits={0}
                        minimumFractionDigits={0}
                        style={globalStyles.h2} />
                </View>
            </View>
        ) : (
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
                    </View>
                    <View>
                        <Text style={globalStyles.h2}>
                            {(item.value * 100).toFixed(2)}%
                        </Text >
                    </View>
                </View>
            );
    }

    render() {
        const { stats } = this.props.portfolio;
        const { accountId } = this.props;

        if (accountId === null || accountId === undefined || accountId === '') {
            return null;
        }
        const accountStats = stats.byAccount.find(x => x.id === accountId);
        if (accountStats === null || accountStats === undefined) {
            return null;
        }

        if (accountStats.records.length < 1) {
            return null;
        }

        const last = accountStats.records[accountStats.records.length - 1];
        const first = accountStats.records[0];

        const totalGrowth = last.total - first.total;
        const totalGrowthPerc = first.total !== 0 ? totalGrowth / first.total : 0;

        const totalData = [
            { name: 'Growth', value: totalGrowth, type: 'currency' },
            { name: 'Growth %', value: totalGrowthPerc, type: 'percent' },
            { name: 'Profit/Loss', value: last.totalPL, type: 'currency' },
            { name: 'Profit/Loss %', value: last.totalPLPercent, type: 'percent' },
            { name: 'TWRR', value: last.twrrPercent, type: 'percent' },
            { name: 'Netflows', value: last.totalNetflows, type: 'currency' },
        ];

        const ytdData = [
            { name: 'Growth', value: last.yearlyGrowth, type: 'currency' },
            { name: 'Growth %', value: last.yearlyGrowthPercent, type: 'percent' },
            { name: 'Profit/Loss', value: last.yearlyPL, type: 'currency' },
            { name: 'Profit/Loss %', value: last.yearlyPLPercent, type: 'percent' },
            { name: 'TWRR', value: last.yearlyTwrrPercent, type: 'percent' },
            { name: 'Netflows', value: last.yearlyNetflows, type: 'currency' },
            { name: 'Netflows (Tax Year)', value: last.taxYearNetflows, type: 'currency' },
        ]


        const sections = [
            { title: 'YTD', data: ytdData },
            { title: 'Total', data: totalData },
        ];


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

// const mapStateToProps = (state) => {
//     const { portfolio } = state
//     return { portfolio }
// };

// export default connect(mapStateToProps)(withNavigation(PortfolioList));
