import React from 'react'
import { StackedAreaChart, YAxis, Grid } from 'react-native-svg-charts'
import * as shape from 'd3-shape'
import * as scale from 'd3-scale'
import { View } from 'react-native'

class StackedAccountGrowthChart extends React.PureComponent {

    constructor(props) {
        super(props);
    }

    render() {

        const { data, keys } = this.props;

        const length = (keys || []).length;

        const colorsFunc = scale.scaleOrdinal()
            .domain([0, length])
            .range(["#1E2833",
                "#2A4054",
                "#5E7A92",
                "#A1B3C4",
                "#CBD5E0",
                "#E5E7EE"]);
        const colors = [...Array(length).keys()].map(x => colorsFunc(x));

        return (
            <View style={{ flexDirection: 'row', height: 200 }}>
                <StackedAreaChart
                    style={{ flex: 1 }}
                    contentInset={{ top: 10, bottom: 10 }}
                    data={data}
                    keys={keys}
                    colors={colors}
                    curve={shape.curveNatural}
                >
                </StackedAreaChart>
                
            </View>
        )
    }
}

export default StackedAccountGrowthChart