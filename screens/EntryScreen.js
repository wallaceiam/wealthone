import React from 'react';
import {
  SafeAreaView,
  ScrollView,
  View,
  TextInput,
  TouchableOpacity,
  SectionList,
  Text,
  DatePickerIOS,
  Button,
  Animated,
  SegmentedControlIOS
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view'
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { globalStyles } from './../Style';
import { globalColours } from './../Colours';

import { saveEntry } from './../redux/Actions';
import { IsAsset } from '../models/Account';
import { justDate, sameDay } from '../helpers/Date';
import { FloatingLabelTextInput } from '../components/FloatingLabelTextInput';
import { NumericInput } from '../components/NumericInput';

class EntryScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Entry',
    headerBackTitle: null,
    headerBackImage: <FeatherIcon name="chevron-left" size={28} color={globalColours.primary} />,
    headerRight: navigation.getParam('saveEntry') ? (
      <Button
        onPress={navigation.getParam('saveEntry')}
        title="Save"
        color={globalColours.primary}
      />) : null
  });

  constructor(props) {
    super(props);
    this.state = {
      record: {
        date: justDate(new Date()),
        totals: [], inflows: [], outflows: [],
      },
      isDateExpanded: false,
      selectedIndex: 0,
      animation: new Animated.Value(32)
    };
    this.setDate = this.setDate.bind(this);
    this.setToday = this.setToday.bind(this);
  }

  setDate(newDate) {
    const { record } = this.state;
    record.date = newDate;
    this.setState({ record: record });
  }

  componentDidMount() {
    this.props.navigation.setParams({ saveEntry: this.onSaveEntry });
    // const entry = this.props.navigation.getParam('entry', { date: justDate(new Date()), totals: [], inflows: [], outflows: [] });
    const date = this.props.navigation.getParam('date', new Date());
    this._loadDate(date);
  }

  _loadDate(date) {
    const accounts = (this.props.portfolio.accounts || []);
    const records = (this.props.portfolio.records || []);
    const totals = accounts.map(x => {
      const r = records.find(y => sameDay(y.date, date));
      const re = r !== null && r !== undefined ? r.totals.find(y => y.id === x.id) : null;
      return {
        id: x.id,
        amount: re !== null && re !== undefined ? re.amount : null
      };
    });
    const inflows = accounts.map(x => {
      const r = records.find(y => sameDay(y.date, date));
      const re = r !== null && r !== undefined ? r.inflows.find(y => y.id === x.id) : null;
      return {
        id: x.id,
        amount: re !== null && re !== undefined ? re.amount : null
      };
    });
    const outflows = accounts.map(x => {
      const r = records.find(y => sameDay(y.date, date));
      const re = r !== null && r !== undefined ? r.outflows.find(y => y.id === x.id) : null;
      return {
        id: x.id,
        amount: re !== null && re !== undefined ? re.amount : null
      };
    });
    this.setState({ record: { date: date, totals: totals, inflows: inflows, outflows: outflows } });
  }

  onSaveEntry = () => {
    this.props.saveEntry(this.state.record);
    this.props.navigation.goBack();
  }

  onToggleDate = () => {
    //Step 1
    let initialValue = this.state.isDateExpanded ? this.state.maxHeight + this.state.minHeight : this.state.minHeight,
      finalValue = this.state.isDateExpanded ? this.state.minHeight : this.state.maxHeight + this.state.minHeight;

    if (this.state.isDateExpanded) {
      this._loadDate(this.state.record.date);
    }
    this.setState({
      isDateExpanded: !this.state.isDateExpanded  //Step 2
    });

    this.state.animation.setValue(initialValue);  //Step 3
    Animated.spring(     //Step 4
      this.state.animation,
      {
        toValue: finalValue
      }
    ).start();  //Step 5
  }

  setToday() {
    this.setDate(new Date());
  }

  setAmount(id, amount) {
    const tAmount = Number.parseInt(amount);
    const dAmount = +(isNaN(tAmount) ? null : tAmount);

    const { date, totals, inflows, outflows } = this.state.record;
    switch (this.state.selectedIndex) {
      case 0: {
        totals.find(x => x.id === id).amount = dAmount;
        break;
      }
      case 1: {
        inflows.find(x => x.id === id).amount = dAmount;
        break;
      }
      case 2: {
        outflows.find(x => x.id === id).amount = dAmount;
        break;
      }
    }
    this.setState({ record: { date: date, totals: totals, inflows: inflows, outflows: outflows } });

  }

  getAmount(id) {

    const values = this.state.selectedIndex === 0 ? this.state.record.totals :
      (this.state.selectedIndex === 1 ? this.state.record.inflows : this.state.record.outflows);
    const value = values.find(x => x.id === id);
    return value !== undefined && value.amount !== null ? value.amount.toString() : null;
  }

  renderItem = ({ item }) => {
    return (
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
        <View style={{ flex: 1 }}>
          <NumericInput
            placeholder="0"
            onChangeText={(text) => this.setAmount(item.id, text)}
            value={this.getAmount(item.id)}
          />
        </View>
      </View>
    );
  }

  renderDateItem = ({ item }) => {
    const date = this.state.record.date;
    return (
      <Animated.View style={[{
        flex: 1,
        flexDirection: 'column',
        justifyContent: 'flex-start',
        marginLeft: 32,
        marginRight: 32,
      },
      { height: this.state.animation }
      ]}>
        <View onLayout={this._setMinHeight.bind(this)}
          style={{ height: 32 }}>
          <View style={{
            flex: 1,
            flexDirection: 'row',
            justifyContent: 'space-between'
          }}>

            <View style={{
              flex: 1,
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}>
              <Text>Date</Text>
            </View>
            <View style={{ flex: 1, borderBottomWidth: 1, borderBottomColor: '#E7E7E7' }}>
              <TouchableOpacity onPress={this.onToggleDate.bind(this)}>
                <Text style={{ textAlign: 'right' }}>{date.toDateString()}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
        <View onLayout={this._setMaxHeight.bind(this)}>
          <DatePickerIOS
            mode='date'
            maximumDate={new Date()}
            date={this.state.record.date}
            onDateChange={this.setDate}
          />
        </View>
      </Animated.View>
    )
  }

  _setMaxHeight(event) {
    this.setState({
      maxHeight: event.nativeEvent.layout.height
    });
  }

  _setMinHeight(event) {
    this.setState({
      minHeight: event.nativeEvent.layout.height,
    });
  }

  render() {
    const accounts = (this.props.portfolio.accounts || []);
    const accountSections = [
      { data: accounts.filter(x => x.isAsset === IsAsset.Asset), title: 'Assets' },
      { data: accounts.filter(x => x.isAsset === IsAsset.Liability), title: 'Liabilities' }
    ];

    const dateSections = [
      { data: [{ value: { date: this.state.record.date, isDateExpanded: this.state.isDateExpanded } }], title: 'Date' }
    ];


    return (
      <SafeAreaView style={globalStyles.safeAreaView}>

        <KeyboardAwareScrollView style={globalStyles.container}
          contentContainerStyle={globalStyles.contentContainer}
          keyboardOpeningTime={0}
          extraHeight={128}>
          <SectionList
            sections={dateSections}
            renderItem={this.renderDateItem}
            keyExtractor={(item, index) => index}
            style={globalStyles.bottomMargin}
          />

          <View style={globalStyles.sideMargins}>
            <SegmentedControlIOS
              values={['Total', 'Inflows', 'Outflows']}
              tintColor={globalColours.primary}
              selectedIndex={this.state.selectedIndex}
              onChange={(event) => {
                this.setState({ selectedIndex: event.nativeEvent.selectedSegmentIndex });
              }}
            />
          </View>

          <SectionList
            sections={accountSections}

            renderSectionHeader={({ section }) => <Text style={globalStyles.sectionHeaderStyle}> {section.title} </Text>}
            renderItem={this.renderItem}
            keyExtractor={(item, index) => index}
          />
        </KeyboardAwareScrollView>
      </SafeAreaView>

    );
  }
}

const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    saveEntry,
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(EntryScreen);
