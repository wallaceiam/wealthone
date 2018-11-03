import React from 'react';
import {
    Text,
    View,
    Dimensions,
    AlertIOS
} from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
//import { PieChart } from 'react-native-svg-charts'
import * as scale from 'd3-scale';
import PieChart from './PieChart';

import { globalStyles } from './../Style';

class AssetPieChart extends React.PureComponent {

    constructor(props) {
        super(props);
        this.state = {
            selectedSlice: {
                label: '',
                value: 0
            },
            labelWidth: 0,
            firstSet: false,
        }
    }

    _onLayout(key, value) {
        if (this.state.selectedSlice.label !== key && !this.state.firstSet) {
            setTimeout(() => {
                this.setState({ selectedSlice: { label: key, value: value }, firstSet: true });
            }, 250);
        }

    }
    render() {


        const { labelWidth, selectedSlice } = this.state;
        const { data } = this.props;
        const { label, value } = selectedSlice;

        const length = (data || []).length;
        const colors = scale.scaleOrdinal()
            .domain([0, length])
            .range(["#1E2833", 
                "#2A4054", 
                "#5E7A92", 
                "#A1B3C4", 
                "#CBD5E0", 
                "#E5E7EE"]);

        const total = (data || []).reduce((p, c) => p + c.value, 0);
        // const keys = ['google', 'facebook', 'linkedin', 'youtube', 'Twitter'];
        // const values = [15, 25, 35, 45, 55];
        // const colors = ['#600080', '#9900cc', '#c61aff', '#d966ff', '#ecb3ff']
        //const colors = ['#800060', '#cc0099', '#ff1ac6', '#ff66d9', '#ffb3ec']

        const pieData = data.map((item, index) => {
            const perc = total !== 0 ? ((item.value / total) * 100) : 0;
            return {
                key: item.key,
                value: perc,
                svg: { fill: colors(index), onPress: () => this.setState({ selectedSlice: { label: item.key, value: item.value } }) },
                arc: { 
                    outerRadius: label === item.key ? '125%' : '120%', 
                    innerRadius: label === item.key ? '85%' : '80%', 
                    padAngle: label === item.key ? 0.05 : 0 },
                onPress: () => this.setState({ selectedSlice: { label: item.key, value: item.value } })
            }
        });
        const deviceWidth = Dimensions.get('window').width;
        const firstKey = data.length > 0 ? data[0].key : '';
        const firstValue = data.length > 0 ? data[0].value : 0;

        return (
            <View style={{ justifyContent: 'center', flex: 1 }}
                onLayout={() => this._onLayout(firstKey, firstValue)}>
                <PieChart
                    style={{ height: 200 }}
                    outerRadius={'80%'}
                    innerRadius={'60%'}
                    data={pieData}
                />
                <View
                    onLayout={({ nativeEvent: { layout: { width } } }) => {
                        this.setState({ labelWidth: width });
                    }}
                    style={{
                        position: 'absolute',
                        left: deviceWidth / 2 - labelWidth / 2,
                        textAlign: 'center'
                    }}>
                    <Text style={{textAlign: 'center'}}>{label}</Text>
                    <FormattedCurrency
                            value={value}
                            currency="GBP"
                            maximumFractionDigits={0}
                            minimumFractionDigits={0}
                            style={[globalStyles.h2, { textAlign: 'center'}]} />
                    {/* {`${label} \n ${value}`} */}
                </View>
            </View>
        )
    }
}

export default AssetPieChart;