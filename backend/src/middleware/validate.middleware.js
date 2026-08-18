const { validationResult } = require('express-validator');

/** Reads express-validator results; returns 422 if any errors exist. */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) return next();
  return res.status(422).json({ errors: errors.array().map(e => ({ field: e.path, message: e.msg })) });
};

module.exports = validate;
