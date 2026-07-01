import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';

import AppShell from './components/layout/AppShell';
import LoginPage from './pages/LoginPage';
import MembersPage from './pages/MembersPage';
import ReferralsPage from './pages/ReferralsPage';
import MarketplacePage from './pages/MarketplacePage';
import SettingsPage from './pages/SettingsPage';
import DashboardPage from './pages/DashboardPage';
import ChaptersPage from './pages/ChaptersPage';
import ClubsPage from './pages/ClubsPage';
import CommunityPage from './pages/CommunityPage';
import EventsPage from './pages/EventsPage';
import PaymentsPage from './pages/PaymentsPage';
import PaymentSuccessPage from './pages/PaymentSuccessPage';
import PaymentCancelledPage from './pages/PaymentCancelledPage';
import RewardsPage from './pages/RewardsPage';
import SupportPage from './pages/SupportPage';

import MemberProfilePage from './pages/MemberProfilePage';
import MyProfilePage from './pages/MyProfilePage';
import ChangePasswordPage from './pages/ChangePasswordPage';
import BusinessPortfolioPage from './pages/BusinessPortfolioPage';

export default function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<AppShell><DashboardPage /></AppShell>} />
            <Route path="/members" element={<AppShell><MembersPage /></AppShell>} />
            <Route path="/members/:id" element={<AppShell><MemberProfilePage /></AppShell>} />
            <Route path="/chapters" element={<AppShell><ChaptersPage /></AppShell>} />
            <Route path="/clubs" element={<AppShell><ClubsPage /></AppShell>} />
            <Route path="/community" element={<AppShell><CommunityPage /></AppShell>} />
            <Route path="/events" element={<AppShell><EventsPage /></AppShell>} />
            <Route path="/referrals" element={<AppShell><ReferralsPage /></AppShell>} />
            <Route path="/marketplace" element={<AppShell><MarketplacePage /></AppShell>} />
            <Route path="/payments" element={<AppShell><PaymentsPage /></AppShell>} />
            <Route path="/payment-success" element={<AppShell><PaymentSuccessPage /></AppShell>} />
            <Route path="/payment-cancelled" element={<AppShell><PaymentCancelledPage /></AppShell>} />
            <Route path="/rewards" element={<AppShell><RewardsPage /></AppShell>} />
            <Route path="/support" element={<AppShell><SupportPage /></AppShell>} />
            <Route path="/profile" element={<AppShell><MyProfilePage /></AppShell>} />
            <Route path="/portfolio" element={<AppShell><BusinessPortfolioPage /></AppShell>} />
            <Route path="/change-password" element={<AppShell><ChangePasswordPage /></AppShell>} />
            <Route path="/settings" element={<AppShell><SettingsPage /></AppShell>} />
          </Route>
        </Routes>
      </AuthProvider>
    </Router>
  );
}
