
import React from 'react'
import { Path } from 'react-native-svg'
import { AreaChart, Grid } from 'react-native-svg-charts'
import { Defs, LinearGradient, Stop } from 'react-native-svg'
import * as shape from 'd3-shape'
import * as scale from 'd3-scale'

import { globalColours } from './../Colours';

export class AccountGrowthChart extends React.PureComponent {

    render() {
        const accountId = this.props.accountId;
        if (accountId !== '') {
            const { stats } = this.props.portfolio;

            const { byAccount } = (stats || { byAccount: [] });
            const account = (byAccount || []).length > 0 ? byAccount.find(x => x.id === accountId) : undefined;
            const data = (account.records || []).map((c) => {
                return {
                    date: new Date(Date.parse(c.date)),
                    value: c.total
                }
            });

            const Gradient = ({ index }) => (
                <Defs key={index}>
                    <LinearGradient id={'gradient'} x1={'0%'} y={'0%'} x2={'0%'} y2={'100%'}>
                        <Stop offset={'0%'} stopColor={globalColours.secondary} stopOpacity={0.2} />
                        <Stop offset={'75%'} stopColor={globalColours.white} stopOpacity={0.0} />
                    </LinearGradient>
                </Defs>
            )

            const Line = ({ line }) => (
                <Path
                    key={'line'}
                    d={line}
                    stroke={globalColours.primary}
                    fill={'none'}
                />
            )

            return data.length > 1 ? (
                <AreaChart
                    style={{ height: 200 }}
                    data={data}
                    yAccessor={({ item }) => item.value}
                    xAccessor={({ item }) => item.date}
                    xScale={scale.scaleTime}
                    contentInset={{ top: 30, bottom: 30 }}
                    curve={shape.curveNatural}
                    svg={{ fill: 'url(#gradient)', viewBox: '0 0 200 200' }}
                // svg={{ fill: globalColours.primary_o20 }}
                >
                    <Line />
                    <Defs>
                        <LinearGradient id={'gradient'} x1={'0%'} y={'0%'} x2={'0%'} y2={'100%'}>
                            <Stop offset={'0%'} stopColor={globalColours.primary} stopOpacity={0.2} />
                            <Stop offset={'75%'} stopColor={globalColours.white} stopOpacity={0.0} />
                        </LinearGradient>
                    </Defs>
                </AreaChart>
            ) : null
        } else {
            return null;
        }
    }
}