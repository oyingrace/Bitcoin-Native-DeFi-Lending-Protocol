// Contract Interactions for Bitcoin-Native DeFi Lending
// Clarity 4 Features: Integration with Stacks.js

// Contract addresses (update these after deployment)
const CONTRACTS = {
    lendingPool: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.lending-pool',
    priceOracle: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.price-oracle',
    passkeySigner: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.passkey-signer',
    governance: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.protocol-governance'
};

// State management
let userAddress = null;
let isConnected = false;
let refreshInterval = null;

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    initializeEventListeners();
    updateUIState();
});

// Event Listeners
function initializeEventListeners() {
    // Wallet connection
    document.getElementById('connectWallet').addEventListener('click', connectWallet);
    document.getElementById('passkeyAuth').addEventListener('click', setupPasskey);
    
    // Lending actions
    document.getElementById('depositBtn').addEventListener('click', handleDeposit);
    document.getElementById('withdrawBtn').addEventListener('click', handleWithdraw);
    
    // Borrowing actions
    document.getElementById('addCollateralBtn').addEventListener('click', handleAddCollateral);
    document.getElementById('borrowBtn').addEventListener('click', handleBorrow);
    document.getElementById('repayBtn').addEventListener('click', handleRepay);
    
    // Input listeners for live calculations
    document.getElementById('depositAmount').addEventListener('input', calculateEstimatedEarnings);
    document.getElementById('collateralAmount').addEventListener('input', calculateMaxBorrow);
    document.getElementById('borrowAmount').addEventListener('input', calculateHealthFactor);
}

// Wallet Connection
async function connectWallet() {
    try {
        // This is a placeholder - integrate with Hiro Wallet / Leather Wallet
        const mockAddress = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
        userAddress = mockAddress;
        isConnected = true;
        
        updateConnectedState();
        startDataRefresh();
        
        showNotification('Wallet connected successfully!', 'success');
    } catch (error) {
        console.error('Wallet connection failed:', error);
        showNotification('Failed to connect wallet', 'error');
    }
}

function updateConnectedState() {
    const connectBtn = document.getElementById('connectWallet');
    const passkeyBtn = document.getElementById('passkeyAuth');
    
    if (isConnected) {
        connectBtn.textContent = `${userAddress.substring(0, 6)}...${userAddress.substring(userAddress.length - 4)}`;
        connectBtn.classList.remove('btn-primary');
        connectBtn.classList.add('btn-outline');
        passkeyBtn.style.display = 'flex';
    }
}

// Clarity 4 Feature: Passkey Authentication (secp256r1-verify)
async function setupPasskey() {
    try {
        // In a real implementation, this would use WebAuthn API
        // to create a passkey credential
        
        const publicKeyCredential = await simulatePasskeyCreation();
        
        // Call contract to register passkey
        const registerCall = {
            function: 'register-passkey',
            args: [
                publicKeyCredential.publicKey,  // secp256r1 public key
                'WebAuthn Device'                // device name
            ]
        };
        
        showNotification('Passkey registered. Use hardware wallet for secure transactions!', 'success');
    } catch (error) {
        console.error('Passkey setup failed:', error);
        showNotification('Passkey setup failed', 'error');
    }
}

// Simulate passkey creation (replace with real WebAuthn)
async function simulatePasskeyCreation() {
    // This would use navigator.credentials.create() in production
    return {
        publicKey: new Uint8Array(33)  // 33-byte secp256r1 public key
    };
}

// Lending Functions
async function handleDeposit() {
    const amount = parseFloat(document.getElementById('depositAmount').value);
    if (!amount || amount <= 0) {
        showNotification('Please enter a valid amount', 'error');
        return;
    }
    
    try {
        showNotification('Depositing STX...', 'info');
        
        // Call lending-pool.deposit
        const depositCall = {
            contract: CONTRACTS.lendingPool,
            function: 'deposit',
            args: [Math.floor(amount * 1000000)]  // Convert to micro-STX
        };
        
        // Simulate transaction
        await simulateTransaction(depositCall);
        
        // Update UI
        document.getElementById('depositAmount').value = '';
        refreshUserData();
        
        showNotification(`Successfully deposited ${amount} STX!`, 'success');
    } catch (error) {
        console.error('Deposit failed:', error);
        showNotification('Deposit failed', 'error');
    }
}

async function handleWithdraw() {
    const userDeposits = document.getElementById('userDeposits').textContent;
    const amount = parseFloat(userDeposits);
    
    if (amount <= 0) {
        showNotification('No deposits to withdraw', 'error');
        return;
    }
    
    try {
        showNotification('Withdrawing STX...', 'info');
        
        const withdrawCall = {
            contract: CONTRACTS.lendingPool,
            function: 'withdraw',
            args: [Math.floor(amount * 1000000)]
        };
        
        await simulateTransaction(withdrawCall);
        refreshUserData();
        
        showNotification(`Successfully withdrew ${amount} STX!`, 'success');
    } catch (error) {
        console.error('Withdrawal failed:', error);
        showNotification('Withdrawal failed', 'error');
    }
}

// Borrowing Functions
async function handleAddCollateral() {
    const amount = parseFloat(document.getElementById('collateralAmount').value);
    if (!amount || amount <= 0) {
        showNotification('Please enter a valid amount', 'error');
        return;
    }
    
    try {
        showNotification('Adding collateral...', 'info');
        
        const addCollateralCall = {
            contract: CONTRACTS.lendingPool,
            function: 'add-collateral',
            args: [
                Math.floor(amount * 1000000),
                'STX'
            ]
        };
        
        await simulateTransaction(addCollateralCall);
        
        document.getElementById('collateralAmount').value = '';
        refreshUserData();
        
        showNotification(`Successfully added ${amount} STX collateral!`, 'success');
    } catch (error) {
        console.error('Add collateral failed:', error);
        showNotification('Adding collateral failed', 'error');
    }
}

async function handleBorrow() {
    const amount = parseFloat(document.getElementById('borrowAmount').value);
    if (!amount || amount <= 0) {
        showNotification('Please enter a valid amount', 'error');
        return;
    }
    
    try {
        showNotification('Borrowing STX...', 'info');
        
        const borrowCall = {
            contract: CONTRACTS.lendingPool,
            function: 'borrow',
            args: [Math.floor(amount * 1000000)]
        };
        
        await simulateTransaction(borrowCall);
        
        document.getElementById('borrowAmount').value = '';
        refreshUserData();
        
        showNotification(`Successfully borrowed ${amount} STX!`, 'success');
    } catch (error) {
        console.error('Borrow failed:', error);
        showNotification('Borrow failed', 'error');
    }
}

async function handleRepay() {
    const loanAmount = parseFloat(document.getElementById('userLoan').textContent);
    
    if (loanAmount <= 0) {
        showNotification('No loan to repay', 'error');
        return;
    }
    
    try {
        showNotification('Repaying loan...', 'info');
        
        const repayCall = {
            contract: CONTRACTS.lendingPool,
            function: 'repay',
            args: [Math.floor(loanAmount * 1000000)]
        };
        
        await simulateTransaction(repayCall);
        refreshUserData();
        
        showNotification('Loan repaid successfully!', 'success');
    } catch (error) {
        console.error('Repay failed:', error);
        showNotification('Repayment failed', 'error');
    }
}

// Calculations
function calculateEstimatedEarnings() {
    const amount = parseFloat(document.getElementById('depositAmount').value) || 0;
    const apy = 0.05;  // 5% APY
    const earnings = (amount * apy).toFixed(2);
    document.getElementById('estimatedEarnings').textContent = `${earnings} STX`;
}

function calculateMaxBorrow() {
    const collateral = parseFloat(document.getElementById('collateralAmount').value) || 0;
    const collateralRatio = 1.5;  // 150%
    const maxBorrow = (collateral / collateralRatio).toFixed(2);
    document.getElementById('maxBorrow').textContent = `${maxBorrow} STX`;
}

function calculateHealthFactor() {
    const collateral = parseFloat(document.getElementById('collateralAmount').value) || 0;
    const borrowed = parseFloat(document.getElementById('borrowAmount').value) || 0;
    
    if (borrowed === 0) {
        document.getElementById('healthFactor').textContent = '∞';
        updateHealthIndicator(1000);  // Infinite health
        return;
    }
    
    const healthFactor = ((collateral / borrowed) * 100).toFixed(0);
    document.getElementById('healthFactor').textContent = `${healthFactor}%`;
    updateHealthIndicator(parseFloat(healthFactor));
}

function updateHealthIndicator(healthFactor) {
    const indicator = document.getElementById('healthIndicator');
    const dot = indicator.querySelector('.health-dot');
    const text = indicator.querySelector('span');
    const progressBar = document.getElementById('healthProgressBar');
    
    // Update progress bar (scale from 100% to 200%, showing 120% as minimum safe)
    const progressWidth = Math.min(100, Math.max(0, ((healthFactor - 100) / 100) * 100));
    progressBar.style.width = `${progressWidth}%`;
    
    if (healthFactor >= 150) {
        dot.style.background = '#4CAF50';  // Green
        text.textContent = 'Healthy';
        indicator.style.color = '#4CAF50';
    } else if (healthFactor >= 120) {
        dot.style.background = '#FF9800';  // Orange
        text.textContent = 'Caution';
        indicator.style.color = '#FF9800';
    } else {
        dot.style.background = '#FF5252';  // Red
        text.textContent = 'Liquidation Risk';
        indicator.style.color = '#FF5252';
    }
}

// Data Refresh
function startDataRefresh() {
    refreshUserData();
    refreshInterval = setInterval(refreshUserData, 10000);  // Every 10 seconds
}

async function refreshUserData() {
    if (!isConnected) return;
    
    try {
        // Fetch user deposits
        const deposits = await getContractData('user-deposits', userAddress);
        document.getElementById('userDeposits').textContent = `${(deposits / 1000000).toFixed(2)} STX`;
        
        // Fetch user loan
        const loan = await getContractData('user-loans', userAddress);
        const loanAmount = loan ? (loan.principal / 1000000).toFixed(2) : '0.00';
        document.getElementById('userLoan').textContent = `${loanAmount} STX`;
        
        // Fetch accrued interest (Clarity 4: calculated with stacks-block-time)
        const interest = await getContractData('calculate-current-interest', userAddress);
        document.getElementById('accruedInterest').textContent = `${(interest / 1000000).toFixed(4)} STX`;
        
        // Fetch protocol totals
        const totalDeposits = await getContractData('total-deposits');
        const totalBorrows = await getContractData('total-borrows');
        document.getElementById('totalDeposits').textContent = `$${(totalDeposits / 1000000 * 2).toFixed(2)}`;  // Mock price $2/STX
        document.getElementById('totalBorrows').textContent = `$${(totalBorrows / 1000000 * 2).toFixed(2)}`;
        
    } catch (error) {
        console.error('Data refresh failed:', error);
    }
}

// Helper Functions
async function getContractData(functionName, ...args) {
    // This would use @stacks/transactions in production
    // For now, return mock data
    const mockData = {
        'user-deposits': 1000000000,  // 1000 STX
        'user-loans': { principal: 500000000 },  // 500 STX
        'calculate-current-interest': 12500000,  // 12.5 STX
        'total-deposits': 50000000000,  // 50,000 STX
        'total-borrows': 25000000000   // 25,000 STX
    };
    
    return mockData[functionName] || 0;
}

async function simulateTransaction(callData) {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1500));
    console.log('Transaction simulated:', callData);
    return { txid: '0x' + Math.random().toString(16).substring(2) };
}

function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 1rem 1.5rem;
        border-radius: 12px;
        background: ${type === 'success' ? '#4CAF50' : type === 'error' ? '#FF5252' : '#4A90E2'};
        color: white;
        font-weight: 600;
        z-index: 1000;
        animation: slideIn 0.3s ease;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
    `;
    
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

function updateUIState() {
    // Update UI based on connection state
    if (!isConnected) {
        // Show placeholder data
        document.getElementById('userDeposits').textContent = '0.00 STX';
        document.getElementById('userLoan').textContent = '0.00 STX';
        document.getElementById('accruedInterest').textContent = '0.00 STX';
        document.getElementById('maxBorrow').textContent = '0.00 STX';
        document.getElementById('healthFactor').textContent = '∞';
    }
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        connectWallet,
        handleDeposit,
        handleBorrow,
        calculateHealthFactor
    };
}
