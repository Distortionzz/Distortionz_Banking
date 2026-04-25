const resourceName = 'distortionz_banking';

const app = document.getElementById('bank-app');

const state = {
    data: null,
    activeTab: 'overview',
    transactionSearch: ''
};

const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
});

function nuiFetch(eventName, data = {}) {
    return fetch(`https://${resourceName}/${eventName}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).then((response) => response.json());
}

function money(value) {
    return formatter.format(Number(value || 0));
}

function safe(value) {
    if (value === null || value === undefined) return '';

    return String(value)
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function setVisible(status) {
    app.classList.toggle('hidden', !status);
}

function setTab(tabName) {
    state.activeTab = tabName;

    document.querySelectorAll('.tab-btn').forEach((button) => {
        button.classList.toggle('active', button.dataset.tab === tabName);
    });

    document.querySelectorAll('.tab-page').forEach((page) => {
        page.classList.toggle('active', page.id === `${tabName}-tab`);
    });
}

function transactionLabel(type) {
    const labels = {
        deposit: 'Deposit',
        withdraw: 'Withdraw',
        transfer_sent: 'Transfer Sent',
        transfer_received: 'Transfer Received'
    };

    return labels[type] || type;
}

function renderAccounts() {
    const list = document.getElementById('accounts-list');
    const accounts = state.data?.accounts || [];

    if (!accounts.length) {
        list.innerHTML = '<div class="empty">No accounts found</div>';
        return;
    }

    list.innerHTML = accounts.map((account) => `
        <div class="account-card">
            <h3>${safe(account.type)} / ${safe(account.id)}</h3>
            <p>${safe(account.name)}</p>
            <strong>${money(account.balance)}</strong>
            <p>Available Balance</p>
        </div>
    `).join('');
}

function renderTransactions() {
    const list = document.getElementById('transactions-list');
    const transactions = state.data?.transactions || [];
    const search = state.transactionSearch.toLowerCase();

    const filtered = transactions.filter((transaction) => {
        const haystack = [
            transaction.type,
            transaction.amount,
            transaction.message,
            transaction.receiver,
            transaction.account_id,
            transaction.created_at
        ].join(' ').toLowerCase();

        return haystack.includes(search);
    });

    if (!filtered.length) {
        list.innerHTML = '<div class="empty">No transactions found</div>';
        return;
    }

    list.innerHTML = filtered.map((transaction) => `
        <div class="transaction-card">
            <div>
                <span class="badge ${safe(transaction.type)}">${safe(transactionLabel(transaction.type))}</span>
                <h4>${safe(transaction.account_id)}</h4>
                <p>${safe(transaction.message || 'No message')}</p>
                <p>${safe(transaction.created_at || '')}</p>
            </div>

            <div>
                <div class="amount ${safe(transaction.type)}">${money(transaction.amount)}</div>
                <p>${safe(transaction.receiver || '')}</p>
            </div>
        </div>
    `).join('');
}

function render() {
    if (!state.data) return;

    const data = state.data;
    const player = data.player || {};
    const wallet = data.wallet || {};
    const transactions = data.transactions || [];

    document.getElementById('bank-name').textContent = data.bankName || 'Distortionz Bank';
    document.getElementById('player-name').textContent = player.name || 'Unknown';
    document.getElementById('player-cid').textContent = `CID: ${player.citizenid || 'Unknown'}`;
    document.getElementById('wallet-cash').textContent = money(wallet.cash);
    document.getElementById('welcome-text').textContent = `Welcome back, ${player.name || 'Citizen'}`;

    document.getElementById('stat-bank').textContent = money(wallet.bank);
    document.getElementById('stat-cash').textContent = money(wallet.cash);
    document.getElementById('stat-transactions').textContent = transactions.length;

    renderAccounts();
    renderTransactions();
}

function clearInputs(ids) {
    ids.forEach((id) => {
        const element = document.getElementById(id);

        if (element) {
            element.value = '';
        }
    });
}

document.getElementById('close-btn').addEventListener('click', () => {
    nuiFetch('closeBank');
    setVisible(false);
});

document.querySelectorAll('.tab-btn').forEach((button) => {
    button.addEventListener('click', () => {
        setTab(button.dataset.tab);
    });
});

document.getElementById('transaction-search').addEventListener('input', (event) => {
    state.transactionSearch = event.target.value || '';
    renderTransactions();
});

document.getElementById('deposit-submit').addEventListener('click', async () => {
    const amount = Number(document.getElementById('deposit-amount').value);
    const note = document.getElementById('deposit-note').value;

    const result = await nuiFetch('deposit', {
        amount,
        note
    });

    if (result?.success && result.data) {
        state.data = result.data;
        clearInputs(['deposit-amount', 'deposit-note']);
        render();
        setTab('overview');
    }
});

document.getElementById('withdraw-submit').addEventListener('click', async () => {
    const amount = Number(document.getElementById('withdraw-amount').value);
    const note = document.getElementById('withdraw-note').value;

    const result = await nuiFetch('withdraw', {
        amount,
        note
    });

    if (result?.success && result.data) {
        state.data = result.data;
        clearInputs(['withdraw-amount', 'withdraw-note']);
        render();
        setTab('overview');
    }
});

document.getElementById('transfer-submit').addEventListener('click', async () => {
    const targetCitizenId = document.getElementById('transfer-cid').value;
    const amount = Number(document.getElementById('transfer-amount').value);
    const note = document.getElementById('transfer-note').value;

    const result = await nuiFetch('transfer', {
        targetCitizenId,
        amount,
        note
    });

    if (result?.success && result.data) {
        state.data = result.data;
        clearInputs(['transfer-cid', 'transfer-amount', 'transfer-note']);
        render();
        setTab('overview');
    }
});

window.addEventListener('message', (event) => {
    const payload = event.data;

    if (!payload || !payload.action) return;

    if (payload.action === 'openBank') {
        state.data = payload.data;
        setVisible(true);
        setTab('overview');
        render();
    }

    if (payload.action === 'setBankData') {
        state.data = payload.data;
        render();
    }

    if (payload.action === 'setVisible') {
        setVisible(payload.status);
    }

    if (payload.action === 'closeBank') {
        setVisible(false);
    }
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        nuiFetch('closeBank');
        setVisible(false);
    }
});
