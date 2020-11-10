import React, { useEffect, useLayoutEffect, useState } from 'react';
import {
  SafeAreaView,
  View,
  TouchableOpacity,
  SectionList,
  Text,
  Animated,
} from 'react-native';
import SegmentedControlIOS from '@react-native-community/segmented-control';
import DatePickerIOS from '@react-native-community/datetimepicker';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { useNavigation, useRoute } from '@react-navigation/native';

import { connect } from 'react-redux';

import { useStyle } from '../../Theme';

import { saveEntry } from '../../Redux/Actions';
import { justDate, sameDay, toUtc } from '../../Redux/DateHelpers';
import { IsAsset } from '../../Models/Account';
import { DateInput, NumericInput, SectionHeader } from '../../Components';
import SaveIcon from '../../Components/Icons/SaveIcon';

const EntryScreen = ({ portfolio, dispatch }) => {
  const navigation = useNavigation();
  const route = useRoute();
  const style = useStyle();

  const [selectedIndex, setSelectedIndex] = useState(0);
  const initialDate = route.params['date']
    ? new Date(route.params['date'])
    : toUtc(justDate(new Date()));
  const [date, setDate] = useState<Date>(initialDate);
  const [totals, setTotals] = useState([]);
  const [inflows, setInflows] = useState([]);
  const [outflows, setOutflows] = useState([]);

  const onSaveEntry = () => {
    dispatch(saveEntry({ date, totals, inflows, outflows }));
    navigation.goBack();
  };

  useLayoutEffect(() => {
    navigation.setOptions({
      title: 'Entry',
      headerRight: () => (
        <TouchableOpacity
          style={style.rightMargin}
          onPress={() => onSaveEntry()}>
          <SaveIcon />
        </TouchableOpacity>
      ),
    });
  }, [navigation, onSaveEntry]);

  useEffect(() => {
    const accounts = portfolio.accounts || [];
    const records = portfolio.records || [];
    const _totals = accounts.map((x) => {
      const r = records.find((y) => sameDay(y.date, date));
      const re =
        r !== null && r !== undefined
          ? r.totals.find((y) => y.id === x.id)
          : null;
      return {
        id: x.id,
        amount: re !== null && re !== undefined ? re.amount : null,
      };
    });
    const _inflows = accounts.map((x) => {
      const r = records.find((y) => sameDay(y.date, date));
      const re =
        r !== null && r !== undefined
          ? r.inflows.find((y) => y.id === x.id)
          : null;
      return {
        id: x.id,
        amount: re !== null && re !== undefined ? re.amount : null,
      };
    });
    const _outflows = accounts.map((x) => {
      const r = records.find((y) => sameDay(y.date, date));
      const re =
        r !== null && r !== undefined
          ? r.outflows.find((y) => y.id === x.id)
          : null;
      return {
        id: x.id,
        amount: re !== null && re !== undefined ? re.amount : null,
      };
    });

    setTotals(_totals);
    setInflows(_inflows);
    setOutflows(_outflows);
  }, [date, setTotals, setInflows, setOutflows, portfolio]);

  const setAmount = (id, amount) => {
    const tAmount = Number.parseInt(amount);
    const dAmount = +(isNaN(tAmount) ? null : tAmount);

    switch (selectedIndex) {
      case 0: {
        const _totals = totals.map((x) =>
          x.id === id ? { id, amount: dAmount } : { ...x },
        );
        setTotals(_totals);
        break;
      }
      case 1: {
        const _inflows = inflows.map((x) =>
          x.id === id ? { id, amount: dAmount } : { ...x },
        );
        setInflows(inflows);
        break;
      }
      case 2: {
        const _outflows = outflows.map((x) =>
          x.id === id ? { id, amount: dAmount } : { ...x },
        );
        setOutflows(_outflows);
        break;
      }
    }
  };

  const getAmount = (id) => {
    const values =
      selectedIndex === 0 ? totals : selectedIndex === 1 ? inflows : outflows;
    const value = values.find((x) => x.id === id);
    return value !== undefined && value.amount !== null
      ? value.amount.toString()
      : null;
  };

  const renderItem = ({ item }) => {
    return (
      <View style={style.row}>
        <View style={[style.column, style.noMargins]}>
          <Text style={style.text}>{item.name} </Text>
          <Text style={style.text}>{item.provider} </Text>
        </View>
        <View style={{ flex: 1 }}>
          <NumericInput
            label={null}
            placeholder="0"
            onChangeText={(text) => setAmount(item.id, +text)}
            value={getAmount(item.id)}
          />
        </View>
      </View>
    );
  };

  const accounts = portfolio.accounts || [];
  const accountSections = [
    {
      data: accounts.filter((x) => x.isAsset === IsAsset.Asset),
      title: 'Assets',
    },
    {
      data: accounts.filter((x) => x.isAsset === IsAsset.Liability),
      title: 'Liabilities',
    },
  ];

  return (
    <SafeAreaView style={style.safeAreaView}>
      <KeyboardAwareScrollView
        style={style.container}
        contentContainerStyle={style.contentContainer}
        keyboardOpeningTime={0}
        extraHeight={128}>
        <View style={style.bottomMargin}>
          <DateInput date={date} onDateChanged={(d) => setDate(d)} />
        </View>

        <View style={style.sideMargins}>
          <SegmentedControlIOS
            values={['Total', 'Inflows', 'Outflows']}
            selectedIndex={selectedIndex}
            onChange={(event) =>
              setSelectedIndex(event.nativeEvent.selectedSegmentIndex)
            }
          />
        </View>

        <SectionList
          sections={accountSections}
          renderSectionHeader={({ section }) => (
            <SectionHeader title={section.title} />
          )}
          renderItem={(item) => renderItem(item)}
          
          keyExtractor={(_item, index) => `${index}-${selectedIndex}`}
        />
      </KeyboardAwareScrollView>
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const { portfolio } = state;
  return { portfolio };
};

export default connect(mapStateToProps)(EntryScreen);
