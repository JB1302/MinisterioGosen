using System.Data;
using System.Globalization;
using Dapper;

namespace MinisterioGosenAPI.Infrastructure;

public sealed class PostgreSqlDateTimeHandler
    : SqlMapper.TypeHandler<DateTime>
{
    public override DateTime Parse(object value) => value switch
    {
        DateTime dateTime => dateTime,

        DateOnly dateOnly =>
            dateOnly.ToDateTime(TimeOnly.MinValue),

        string text =>
            DateTime.Parse(text, CultureInfo.InvariantCulture),

        _ => throw new DataException(
            $"No se puede convertir {value.GetType().Name} a DateTime.")
    };

    public override void SetValue(
        IDbDataParameter parameter,
        DateTime value)
    {
        // Conserva el DbType indicado en el controlador.
        parameter.Value = value;
    }
}

public sealed class PostgreSqlTimeSpanHandler
    : SqlMapper.TypeHandler<TimeSpan>
{
    public override TimeSpan Parse(object value) => value switch
    {
        TimeSpan timeSpan => timeSpan,

        TimeOnly timeOnly => timeOnly.ToTimeSpan(),

        string text =>
            TimeSpan.Parse(text, CultureInfo.InvariantCulture),

        _ => throw new DataException(
            $"No se puede convertir {value.GetType().Name} a TimeSpan.")
    };

    public override void SetValue(
        IDbDataParameter parameter,
        TimeSpan value)
    {
        // Conserva el DbType indicado en el controlador.
        parameter.Value = value;
    }
}