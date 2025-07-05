interface TicketDetailsProps {
  properties: Record<string, unknown> | null;
}

const TicketDetails = ({ properties }: TicketDetailsProps) => {
  if (!properties) {
    return null;
  }

  const filteredProperties = Object.entries(properties).filter(([key]) =>
    !['updated_at'].includes(key)
  );

  return (
    <div style={{ textAlign: 'left', marginTop: '1rem' }}>
      <h4>Ticket Properties</h4>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <tbody>
          {filteredProperties.map(([key, value]) => (
            <tr key={key} style={{ borderBottom: '1px solid #eee' }}>
              <td style={{ padding: '8px', fontWeight: 'bold', textTransform: 'capitalize' }}>
                {key.replace(/_/g, ' ')}
              </td>
              <td style={{ padding: '8px', wordBreak: 'break-all' }}>
                {key.endsWith('_date') || key === 'created_at' ? new Date(value).toLocaleString() : String(value)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default TicketDetails;
