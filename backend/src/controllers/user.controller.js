exports.getProfile = async (req, res) => res.json({ profile: req.user });
exports.updateProfile = async (req, res) => res.json({ profile: req.user });
exports.deleteAccount = async (req, res) => res.json({ message: 'Account deleted' });
