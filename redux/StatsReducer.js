import { AccountTypes } from "../models/Account";


export const statsReducer = (state, action, dispatch) => {
    if(action.type.startsWith('@@redux') || action.type.startsWith('persist')) {
        return state;
    }
    const orderedRecords = state.records.sort(recordDateSort);
    const netWorth = orderedRecords.map((c) => {
        return {
            date: c.date,
            assets: c.totals.reduce((tp, tc) => {
                const account = state.accounts.find(x => x.id === tc.id);
                return tp + (account !== null & account.accountType == AccountTypes.Asset ? tc.amount : 0);
            }, 0),
            liabilities: c.totals.reduce((tp, tc) => {
                const account = state.accounts.find(x => x.id === tc.id);
                return tp + (account !== null & account.accountType == AccountTypes.Liability ? tc.amount : 0);
            }, 0),
            inflows: c.inflows.reduce((tp, tc) => {
                const account = state.accounts.find(x => x.id === tc.id);
                return tp + (account !== null && tc.amount != null ? tc.amount : 0);
            }, 0),
            outflows: c.outflows.reduce((tp, tc) => {
                const account = state.accounts.find(x => x.id === tc.id);
                return tp + (account !== null && tc.amount != null ? tc.amount : 0);
            }, 0),
        }
    }).map((c)=> {
        return {
            ...c,
            total: c.assets - c.liabilities,
            netflows: c.inflows - c.outflows,

        };
    }).reduce((p, c, i) => {
        const twrr_raw = i > 0 && p[i-1].total !== 0 ? ((c.total - c.netflows) - p[i-1].total) / p[i-1].total : 1
        const twrr_percent = p.reduce((tp, tc) => 1 + (tp * tc.twrrRaw), 1) * (1 + twrr_raw) - 1;
        p.push({...c,
            changeAmount: i > 0 ? c.total - p[i-1].total : 0,
            changePercent: i > 0 && p[i-1].total !== 0 ? (c.total - p[i-1].total) / p[i-1].total : 0,
            twrrRaw: twrr_raw,
            twrrPercent: twrr_percent,
        });
        return p;
    }, []);
    const byAccount = state.accounts.map((c) => {
        return {
            id: c.id,
            records: orderedRecords.map((oc) => {
                const total = oc.totals.find(x => x.id === c.id);
                const inflow = oc.inflows.find(x => x.id === c.id);
                const outflow = oc.outflows.find(x => x.id === c.id);
                return {
                    date: new Date(Date.parse(oc.date)),
                    total: total !== null && total !== undefined ? total.amount : 0,
                    inflow: inflow !== null && inflow !== undefined ? inflow.amount : 0,
                    outflow: outflow !== null && outflow !== undefined ? outflow.amount : 0
                };
            }).map((oc) => {
                return {
                    ...oc,
                    netflow: oc.inflow - oc.outflow
                };
            }).reduce((op, oc, i) => {
                const twrr_raw = i > 0 && op[i-1].total !== 0 ? ((oc.total - oc.netflow) - op[i-1].total) / op[i-1].total : 1
                const twrr_percent = op.reduce((tp, tc) => 1 + (tp * tc.twrrRaw), 1) * (1 + twrr_raw) - 1;
                op.push({...oc,
                    changeAmount: i > 0 ? oc.total - op[i-1].total : 0,
                    changePercent: i > 0 && op[i-1].total !== 0 ? (oc.total - op[i-1].total) / op[i-1].total : 0,
                    twrrRaw: twrr_raw,
                    twrrPercent: twrr_percent,
                });
                return op;
            }, [])
        }
    })
    return { ...state, stats: { netWorth: netWorth, byAccount: byAccount }, };
}

const recordDateSort = (a, b) => {
    return dateSort(a.date, b.date);
}

const dateSort = (d1, d2) => {
    const da = d1 instanceof Date ? d1 : new Date(Date.parse(d1));
    const db = d2 instanceof Date ? d2 : new Date(Date.parse(d2));
    return da.getTime() - db.getTime();
}

