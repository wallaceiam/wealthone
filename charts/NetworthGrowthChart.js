import React from 'react'
import { AreaChart } from 'react-native-svg-charts'
import { Path, Defs, LinearGradient, Stop } from 'react-native-svg'
import * as shape from 'd3-shape'
import * as scale from 'd3-scale'

import { globalColours } from './../Colours';

export class NetworthGrowthChart extends React.Component {

    render() {
        const { stats } = this.props.portfolio;
        const { netWorth } = (stats || { netWorth: [] });
        const data = (netWorth || []).map((c) => {
            return {
                date: new Date(Date.parse(c.date)),
                value: c.total
            }
        });

        const Gradient = (any) => (
            <Defs>
                <LinearGradient id={'gradient'} x1={'0%'} y={'0%'} x2={'0%'} y2={'100%'}>
                    <Stop offset={'0%'} stopColor={globalColours.secondary} stopOpacity={0.2} />
                    <Stop offset={'75%'} stopColor={globalColours.secondary} stopOpacity={0.0} />
                </LinearGradient>
            </Defs>
        )

        const Line = ({ line }) => (
            <Path
                key={'line'}
                d={line}
                stroke={globalColours.secondary}
                fill={'none'}
            />
        )

        return (
            <AreaChart
                style={{ height: 200 }}
                data={data}
                yAccessor={({ item }) => item.value}
                xAccessor={({ item }) => item.date}
                xScale={scale.scaleTime}
                contentInset={{ top: 30, bottom: 30 }}
                curve={shape.curveNatural}
                svg={{ fill: 'url(#gradient)' }}
            // svg={{ fill: globalColours.primary_o20 }}
            >
                <Line />
                <Defs key={'gradient'}>
                    <LinearGradient id={'gradient'} x1={'0%'} y={'0%'} x2={'0%'} y2={'100%'}>
                        <Stop offset={'0%'} stopColor={globalColours.secondary} stopOpacity={0.2} />
                        <Stop offset={'75%'} stopColor={globalColours.white} stopOpacity={0.0} />
                    </LinearGradient>
                </Defs>
            </AreaChart>
        )
    }
}